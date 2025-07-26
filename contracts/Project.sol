// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint256 public listingFee = 0.01 ether;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    constructor() ERC721("MyNFT", "MNFT") {}

    // Mint and list NFT
    function createToken(string memory tokenURI, uint256 price) public payable nonReentrant returns (uint256) {
        require(price > 0, "Price must be at least 1 wei");
        require(msg.value == listingFee, "Must pay listing fee");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        createMarketItem(newTokenId, price);

        return newTokenId;
    }

    function createMarketItem(uint256 tokenId, uint256 price) private {
        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId);
    }

    // Buy NFT
    function createMarketSale(uint256 tokenId) public payable nonReentrant {
        MarketItem storage item = idToMarketItem[tokenId];
        require(msg.value == item.price, "Please submit the asking price");

        item.owner = payable(msg.sender);
        item.sold = true;
        _itemsSold.increment();

        _transfer(address(this), msg.sender, tokenId);
        item.seller.transfer(msg.value);
    }

    // ✅ Resell NFT owned by user
    function resellToken(uint256 tokenId, uint256 price) public payable nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "You do not own this token");
        require(msg.value == listingFee, "Must pay listing fee");
        require(price > 0, "Price must be greater than 0");

        MarketItem storage item = idToMarketItem[tokenId];
        item.sold = false;
        item.price = price;
        item.seller = payable(msg.sender);
        item.owner = payable(address(this));
        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }

    // Fetch NFTs created by user
    function fetchNFTsCreatedByUser() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    // Fetch NFTs owned by user
    function fetchNFTsOwnedByUser() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    // Fetch unsold market items
    function fetchUnsoldMarketItems() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 unsoldItemCount = totalItemCount - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            uint256 currentId = i + 1;
            MarketItem storage currentItem = idToMarketItem[currentId];
            if (!currentItem.sold) {
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    // Fetch all market items
    function fetchAllMarketItems() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        MarketItem[] memory items = new MarketItem[](totalItemCount);

        for (uint256 i = 0; i < totalItemCount; i++) {
            uint256 currentId = i + 1;
            MarketItem storage currentItem = idToMarketItem[currentId];
            items[i] = currentItem;
        }

        return items;
    }

    // ✅ Get details of a specific NFT by tokenId
    function getMarketItemDetails(uint256 tokenId) public view returns (MarketItem memory) {
        require(tokenId > 0 && tokenId <= _tokenIds.current(), "Invalid tokenId");
        return idToMarketItem[tokenId];
    }

    // Update listing fee
    function updateListingFee(uint256 newFee) public onlyOwner {
        listingFee = newFee;
    }

    // Withdraw listing fees
    function withdrawFees() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

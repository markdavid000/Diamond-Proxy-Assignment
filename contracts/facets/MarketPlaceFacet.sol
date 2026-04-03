// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";

contract MarketplaceFacet {
    event ListingCreated(uint256 indexed listingId, uint256 tokenId, uint256 price);
    event ListingSold(uint256 indexed listingId, uint256 tokenId, address buyer);
    event ListingRemoved(uint256 indexed listingId);

    function createListing(uint256 _tokenId, uint256 _price) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        // Transfer NFT to diamond
        IERC721(ds.erc721Token).transferFrom(msg.sender, address(this), _tokenId);
        
        uint256 listingId = ds.listingCount++;
        LibDiamond.Listing storage listing = ds.listings[listingId];
        
        listing.seller = msg.sender;
        listing.tokenId = _tokenId;
        listing.price = _price;
        listing.active = true;
        
        emit ListingCreated(listingId, _tokenId, _price);
    }

    function purchaseNFT(uint256 _listingId) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Listing storage listing = ds.listings[_listingId];
        
        require(listing.active, "Listing not active");
        require(msg.sender != listing.seller, "Cannot buy own");
        
        // Transfer ERC20 to seller
        IERC20(ds.erc20Token).transferFrom(msg.sender, listing.seller, listing.price);
        
        // Transfer NFT to buyer
        IERC721(ds.erc721Token).transferFrom(address(this), msg.sender, listing.tokenId);
        
        listing.active = false;
        
        emit ListingSold(_listingId, listing.tokenId, msg.sender);
    }

    function removeListing(uint256 _listingId) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Listing storage listing = ds.listings[_listingId];
        
        require(msg.sender == listing.seller, "Not seller");
        require(listing.active, "Not active");
        
        IERC721(ds.erc721Token).transferFrom(address(this), msg.sender, listing.tokenId);
        
        listing.active = false;
        
        emit ListingRemoved(_listingId);
    }

    function fetchListingDetails(uint256 _listingId) external view returns (
        address seller,
        uint256 tokenId,
        uint256 price,
        bool active
    ) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Listing storage listing = ds.listings[_listingId];
        
        return (listing.seller, listing.tokenId, listing.price, listing.active);
    }
}
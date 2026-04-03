// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibDiamond {
    // Diamond Storage Slot
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }
    // Facet structure
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    // Main Diamond Storage
    struct DiamondStorage {
        // Facet management
        mapping(bytes4 => address) selectorToFacet;
        mapping(address => Facet) facets;
        address[] facetAddresses;
        // Ownership
        address owner;
        // Multisig
        mapping(address => bool) isSigner;
        uint256 requiredSignatures;
        uint256 proposalCount;
        mapping(uint256 => Proposal) proposals;
        // ERC20 Token Address
        address erc20Token;
        // ERC721 Token Address
        address erc721Token;
        // Staking
        mapping(address => uint256) stakingBalance;
        mapping(address => uint256) stakingLastUpdate;
        mapping(address => uint256) stakingRewards;
        uint256 stakingRate; // rewards per second
        // NFT Metadata (for SVG)
        mapping(uint256 => string) nftNames;
        mapping(uint256 => string) nftDescriptions;
        // Borrowing
        mapping(uint256 => Loan) loans;
        uint256 loanCount;
        // Marketplace
        mapping(uint256 => Listing) listings;
        uint256 listingCount;
    }

    // Proposal for multisig
    struct Proposal {
        address[] targets;
        bytes[] calldatas;
        uint256 votes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    // Loan structure
    struct Loan {
        address borrower;
        uint256 tokenId;
        uint256 collateral;
        uint256 duration;
        uint256 startTime;
        bool active;
    }

    // Marketplace listing
    struct Listing {
        address seller;
        uint256 tokenId;
        uint256 price;
        bool active;
    }

    // Get Diamond Storage
    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // Get Facet Address for selector
    function facetAddress(bytes4 _selector) internal view returns (address) {
        DiamondStorage storage ds = diamondStorage();
        return ds.selectorToFacet[_selector];
    }
}

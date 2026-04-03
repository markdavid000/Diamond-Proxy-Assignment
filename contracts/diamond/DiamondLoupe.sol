// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";

contract DiamondLoupeFacet {
    function facets() external view returns (LibDiamond.Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 count = ds.facetAddresses.length;
        
        facets_ = new LibDiamond.Facet[](count);
        
        for (uint256 i = 0; i < count; i++) {
            address fAddr = ds.facetAddresses[i];  // ✅ 'fAddr' avoids shadowing
            facets_[i].facetAddress = fAddr;
            facets_[i].functionSelectors = ds.facets[fAddr].functionSelectors;
        }
        
        return facets_;
    }

    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.facets[_facet].functionSelectors;
    }

    function facetAddresses() external view returns (address[] memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.facetAddresses;
    }

    function facetAddress(bytes4 _functionSelector) external view returns (address) {
        return LibDiamond.facetAddress(_functionSelector);
    }
}
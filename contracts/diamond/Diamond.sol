// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./DiamondCut.sol";
import "./Ownership.sol";
import "./DiamondLoupe.sol";
import "../libraries/LibDiamond.sol";

contract Diamond {
    constructor(address _owner, address _cutFacet) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.owner = _owner;
        
        // Add DiamondCutFacet
        LibDiamond.Facet memory cutFacet;
        cutFacet.facetAddress = _cutFacet;
        cutFacet.functionSelectors = new bytes4[](4);
        cutFacet.functionSelectors[0] = DiamondCutFacet.diamondCut.selector;
        cutFacet.functionSelectors[1] = DiamondCutFacet.createProposal.selector;
        cutFacet.functionSelectors[2] = DiamondCutFacet.vote.selector;
        cutFacet.functionSelectors[3] = DiamondCutFacet.executeProposal.selector;
        
        ds.facets[_cutFacet] = cutFacet;
        ds.facetAddresses.push(_cutFacet);
        
        for (uint256 i = 0; i < 4; i++) {
            ds.selectorToFacet[cutFacet.functionSelectors[i]] = _cutFacet;
        }
    }

    fallback() external payable {
        address facet = LibDiamond.facetAddress(msg.sig);
        require(facet != address(0), "Diamond: Function not found");
        
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
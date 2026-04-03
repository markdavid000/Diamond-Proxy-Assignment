// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDiamond {
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
}
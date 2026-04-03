// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDiamond.sol";

interface IDiamondCut is IDiamond {
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;
}
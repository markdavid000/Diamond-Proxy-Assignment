// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";

contract OwnershipFacet {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnerUpdated(address indexed newOwner);

    function owner() external view returns (address owner_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        owner_ = ds.owner;
    }

    function transferOwnership(address _newOwner) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.owner, "Not owner");
        require(_newOwner != address(0), "Zero address");
        
        address previousOwner = ds.owner;
        ds.owner = _newOwner;
        
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function updateOwner(address _newOwner) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.owner, "Not owner");
        require(_newOwner != address(0), "Zero address");
        
        ds.owner = _newOwner;
        
        emit OwnerUpdated(_newOwner);
    }
}
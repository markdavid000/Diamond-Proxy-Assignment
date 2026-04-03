// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";
import "../interfaces/IERC20.sol";

contract StakingFacet {
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event RewardsCollected(address indexed user, uint256 amount);

    function stakeTokens(uint256 _amount) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        IERC20(ds.erc20Token).transferFrom(msg.sender, address(this), _amount);
        
        ds.stakingBalance[msg.sender] += _amount;
        ds.stakingLastUpdate[msg.sender] = block.timestamp;
        
        emit TokensStaked(msg.sender, _amount);
    }

    function unstakeTokens(uint256 _amount) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.stakingBalance[msg.sender] >= _amount, "Insufficient");
        
        ds.stakingBalance[msg.sender] -= _amount;
        IERC20(ds.erc20Token).transfer(msg.sender, _amount);
        
        emit TokensUnstaked(msg.sender, _amount);
    }

    function collectRewards() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        uint256 rewards = calculateEarnedRewards(msg.sender);
        require(rewards > 0, "No rewards");
        
        ds.stakingRewards[msg.sender] = 0;
        ds.stakingLastUpdate[msg.sender] = block.timestamp;
        
        IERC20(ds.erc20Token).transfer(msg.sender, rewards);
        
        emit RewardsCollected(msg.sender, rewards);
    }

    function calculateEarnedRewards(address _user) public view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        uint256 timeElapsed = block.timestamp - ds.stakingLastUpdate[_user];
        uint256 pending = (ds.stakingBalance[_user] * ds.stakingRate * timeElapsed) / 1e18;
        
        return ds.stakingRewards[_user] + pending;
    }

    function fetchStakingBalance(address _user) external view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.stakingBalance[_user];
    }

    function updateStakingRate(uint256 _rate) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.owner, "Not owner");
        ds.stakingRate = _rate;
    }
}
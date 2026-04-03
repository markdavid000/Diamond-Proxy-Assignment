// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../contracts/diamond/Diamond.sol";
import "../contracts/diamond/DiamondCut.sol";
import "../contracts/diamond/DiamondLoupe.sol";
import "../contracts/diamond/Ownership.sol";
import "../contracts/facets/MultisigFacet.sol";
import "../contracts/facets/StakingFacet.sol";
import "../contracts/facets/SVGFacet.sol";
import "../contracts/facets/MarketPlaceFacet.sol";
import "../contracts/facets/BorrowerFacet.sol";


contract DeployDiamond is Script {
    function run() external {
        // ========== DEPLOY ALL FACETS ==========
        vm.startBroadcast();

        // 1. Deploy DiamondCutFacet (needed first for Diamond constructor)
        DiamondCutFacet cutFacet = new DiamondCutFacet();
        console.log("DiamondCutFacet deployed:", address(cutFacet));

        // 2. Deploy Diamond (proxy)
        Diamond diamond = new Diamond(msg.sender, address(cutFacet));
        console.log("Diamond deployed:", address(diamond));

        // 3. Deploy other facets
        DiamondLoupeFacet loupeFacet = new DiamondLoupeFacet();
        console.log("DiamondLoupeFacet deployed:", address(loupeFacet));

        OwnershipFacet ownershipFacet = new OwnershipFacet();
        console.log("OwnershipFacet deployed:", address(ownershipFacet));

        MultisigFacet multisigFacet = new MultisigFacet();
        console.log("MultisigFacet deployed:", address(multisigFacet));

        StakingFacet stakingFacet = new StakingFacet();
        console.log("StakingFacet deployed:", address(stakingFacet));

        SVGFacet svgFacet = new SVGFacet();
        console.log("SVGFacet deployed:", address(svgFacet));

        BorrowerFacet borrowerFacet = new BorrowerFacet();
        console.log("BorrowerFacet deployed:", address(borrowerFacet));

        MarketplaceFacet marketplaceFacet = new MarketplaceFacet();
        console.log("MarketplaceFacet deployed:", address(marketplaceFacet));

        vm.stopBroadcast();

        // ========== OUTPUT DEPLOYMENT INFO ==========
        console.log("\n========== DEPLOYMENT COMPLETE ==========");
        console.log("Diamond Address:", address(diamond));
        console.log("Owner:", msg.sender);
        console.log("\nFacet Addresses:");
        console.log("  - CutFacet:", address(cutFacet));
        console.log("  - LoupeFacet:", address(loupeFacet));
        console.log("  - OwnershipFacet:", address(ownershipFacet));
        console.log("  - MultisigFacet:", address(multisigFacet));
        console.log("  - StakingFacet:", address(stakingFacet));
        console.log("  - SVGFacet:", address(svgFacet));
        console.log("  - BorrowerFacet:", address(borrowerFacet));
        console.log("  - MarketplaceFacet:", address(marketplaceFacet));
        console.log("==========================================\n");
    }
}
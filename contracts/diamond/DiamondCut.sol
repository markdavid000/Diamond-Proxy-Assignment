// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";
import "../interfaces/IDiamond.sol";

contract DiamondCutFacet {
    // ========== TYPES ==========
    enum FacetCutAction { Add, Replace, Remove }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    // ========== EVENTS ==========
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
    event ProposalCreated(uint256 indexed proposalId, address creator);
    event VoteCast(uint256 indexed proposalId, address voter);
    event ProposalExecuted(uint256 indexed proposalId);

    // ========== MODIFIERS ==========
    modifier onlySigner() {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.isSigner[msg.sender], "Not a signer");
        _;
    }

    modifier onlyOwner() {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.owner, "Not owner");
        _;
    }

    // ========== MULTISIG PROPOSALS ==========
    function createProposal(
        FacetCut[] calldata cuts,
        address initAddr,
        bytes calldata initCalldata
    ) external onlySigner returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        uint256 proposalId = ds.proposalCount++;
        LibDiamond.Proposal storage proposal = ds.proposals[proposalId];

        proposal.calldatas.push(abi.encode(cuts, initAddr, initCalldata));
        proposal.targets.push(address(this));

        emit ProposalCreated(proposalId, msg.sender);
        return proposalId;
    }

    function vote(uint256 proposalId) external onlySigner {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Proposal storage proposal = ds.proposals[proposalId];

        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(!proposal.executed, "Already executed");

        proposal.hasVoted[msg.sender] = true;
        proposal.votes++;

        emit VoteCast(proposalId, msg.sender);
    }

    function executeProposal(uint256 proposalId) external onlySigner {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Proposal storage proposal = ds.proposals[proposalId];

        require(proposal.votes >= ds.requiredSignatures, "Not enough votes");
        require(!proposal.executed, "Already executed");

        proposal.executed = true;

        (
            FacetCut[] memory cuts,
            address initAddr,
            bytes memory initCalldata
        ) = abi.decode(proposal.calldatas[0], (FacetCut[], address, bytes));

        _applyCuts(cuts, initAddr, initCalldata);

        emit ProposalExecuted(proposalId);
    }

    // ========== DIAMOND CUT (PUBLIC) ==========
    function diamondCut(
        FacetCut[] calldata cuts,
        address initAddr,
        bytes calldata initCalldata
    ) external onlyOwner {
        // Convert calldata → memory for internal processing
        FacetCut[] memory cutsMem = new FacetCut[](cuts.length);
        for (uint256 i = 0; i < cuts.length; i++) {
            cutsMem[i] = cuts[i];
        }

        _applyCuts(cutsMem, initAddr, initCalldata);
    }

    // ========== INTERNAL CUT LOGIC (NO SHADOWING) ==========
    function _applyCuts(
        FacetCut[] memory cuts,
        address initAddr,
        bytes memory initCalldata
    ) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        for (uint256 i = 0; i < cuts.length; i++) {
            address facetAddr = cuts[i].facetAddress;

            if (cuts[i].action == FacetCutAction.Add) {
                ds.facetAddresses.push(facetAddr);
                ds.facets[facetAddr].facetAddress = facetAddr;
            }

            for (uint256 j = 0; j < cuts[i].functionSelectors.length; j++) {
                bytes4 selector = cuts[i].functionSelectors[j];

                if (cuts[i].action == FacetCutAction.Add) {
                    ds.selectorToFacet[selector] = facetAddr;
                    ds.facets[facetAddr].functionSelectors.push(selector);
                } else if (cuts[i].action == FacetCutAction.Replace) {
                    ds.selectorToFacet[selector] = facetAddr;
                } else if (cuts[i].action == FacetCutAction.Remove) {
                    delete ds.selectorToFacet[selector];
                }
            }
        }

        emit DiamondCut(cuts, initAddr, initCalldata);

        if (initAddr != address(0)) {
            (bool success, ) = initAddr.call(initCalldata);
            require(success, "Init failed");
        }
    }

    // ========== ADMIN FUNCTIONS ==========
    function addSigner(address signer) external onlyOwner {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(signer != address(0), "Zero address");
        ds.isSigner[signer] = true;
    }

    function removeSigner(address signer) external onlyOwner {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.isSigner[signer] = false;
    }

    function setRequiredSignatures(uint256 count) external onlyOwner {
        require(count > 0, "Must be > 0");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.requiredSignatures = count;
    }

    function setTokenAddresses(address erc20, address erc721) external onlyOwner {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.erc20Token = erc20;
        ds.erc721Token = erc721;
    }

    // ========== VIEW FUNCTIONS ==========
    function isSigner(address account) external view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.isSigner[account];
    }

    function getRequiredSignatures() external view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.requiredSignatures;
    }

    function getProposalCount() external view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.proposalCount;
    }
}
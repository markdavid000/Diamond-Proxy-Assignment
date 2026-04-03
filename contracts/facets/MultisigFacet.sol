// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";

contract MultisigFacet {
    // ========== EVENTS ==========
    event SignerRegistered(address indexed signer);
    event SignerDeregistered(address indexed signer);
    event ProposalSubmitted(uint256 indexed proposalId, address creator);
    event ApprovalCast(uint256 indexed proposalId, address voter);
    event ProposalFinalized(uint256 indexed proposalId);
    event ProposalRevoked(uint256 indexed proposalId);

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

    // ========== SIGNER MANAGEMENT ==========
    function registerSigner(address signer) external onlyOwner {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(signer != address(0), "Zero address");
        require(!ds.isSigner[signer], "Already signer");
        ds.isSigner[signer] = true;
        emit SignerRegistered(signer);
    }

    function deregisterSigner(address signer) external onlyOwner {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.isSigner[signer] = false;
        emit SignerDeregistered(signer);
    }

    function updateRequiredSignatures(uint256 count) external onlyOwner {
        require(count > 0, "Must be > 0");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.requiredSignatures = count;
    }

    function verifyIsSigner(address account) external view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.isSigner[account];
    }

    function fetchRequiredSignatures() external view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.requiredSignatures;
    }

    // ========== PROPOSAL MANAGEMENT ==========
    function submitProposal(
        LibDiamond.FacetCut[] calldata cuts,
        address initAddr,
        bytes calldata initCalldata
    ) external onlySigner returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        uint256 proposalId = ds.proposalCount++;
        LibDiamond.Proposal storage proposal = ds.proposals[proposalId];
        
        proposal.targets.push(address(this));
        proposal.calldatas.push(abi.encode(cuts, initAddr, initCalldata));
        
        emit ProposalSubmitted(proposalId, msg.sender);
        return proposalId;
    }

    function castApproval(uint256 proposalId) external onlySigner {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Proposal storage proposal = ds.proposals[proposalId];
        
        require(!proposal.executed, "Already executed");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        proposal.hasVoted[msg.sender] = true;
        proposal.votes++;
        
        emit ApprovalCast(proposalId, msg.sender);
    }

    function finalizeProposal(uint256 proposalId) external onlySigner {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Proposal storage proposal = ds.proposals[proposalId];
        
        require(proposal.votes >= ds.requiredSignatures, "Not enough votes");
        require(!proposal.executed, "Already executed");
        
        proposal.executed = true;
        
        (
            LibDiamond.FacetCut[] memory cuts,
            address initAddr,
            bytes memory initCalldata
        ) = abi.decode(proposal.calldatas[0], (LibDiamond.FacetCut[], address, bytes));
        
        _applyCuts(cuts, initAddr, initCalldata);
        
        emit ProposalFinalized(proposalId);
    }

    function revokeProposal(uint256 proposalId) external onlyOwner {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Proposal storage proposal = ds.proposals[proposalId];
        
        require(!proposal.executed, "Already executed");
        proposal.executed = true;
        emit ProposalRevoked(proposalId);
    }

    function fetchProposalDetails(uint256 proposalId) external view returns (
        address[] memory targets,
        bytes[] memory calldatas,
        uint256 votes,
        bool executed
    ) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Proposal storage proposal = ds.proposals[proposalId];
        return (proposal.targets, proposal.calldatas, proposal.votes, proposal.executed);
    }

    function checkHasApproved(uint256 proposalId, address account) external view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.proposals[proposalId].hasVoted[account];
    }

    function fetchProposalCount() external view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.proposalCount;
    }

    // ========== INTERNAL CUT LOGIC ==========
    function _applyCuts(
        LibDiamond.FacetCut[] memory cuts,
        address initAddr,
        bytes memory initCalldata
    ) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        for (uint256 i = 0; i < cuts.length; i++) {
            address facetAddr = cuts[i].facetAddress;
            
            if (cuts[i].action == LibDiamond.FacetCutAction.Add) {
                ds.facetAddresses.push(facetAddr);
                ds.facets[facetAddr].facetAddress = facetAddr;
            }
            
            for (uint256 j = 0; j < cuts[i].functionSelectors.length; j++) {
                bytes4 selector = cuts[i].functionSelectors[j];
                
                if (cuts[i].action == LibDiamond.FacetCutAction.Add) {
                    ds.selectorToFacet[selector] = facetAddr;
                    ds.facets[facetAddr].functionSelectors.push(selector);
                } else if (cuts[i].action == LibDiamond.FacetCutAction.Replace) {
                    ds.selectorToFacet[selector] = facetAddr;
                } else if (cuts[i].action == LibDiamond.FacetCutAction.Remove) {
                    delete ds.selectorToFacet[selector];
                }
            }
        }
        
        if (initAddr != address(0)) {
            (bool success, ) = initAddr.call(initCalldata);
            require(success, "Init failed");
        }
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SilensModel.sol";
import "./SilensReputation.sol";
import "./SilensProposal.sol";
import "./SilensIdentityRegistry.sol";

// ==================== SilensCore Contract ====================
contract Silens is Ownable {
    SilensModel public modelRegistry;
    SilensReputation public reputationSystem;
    SilensProposal public proposalVoting;
    SilensIdentityRegistry public identitySystem;
    
    mapping(uint256 => uint256) public modelToProposal;
    
    event SystemInitialized(address modelRegistry, address reputationSystem, address proposalVoting, address identitySystem);
    event AutoProposalCreated(uint256 indexed modelId, uint256 indexed proposalId);
    
    constructor(
        address _modelRegistry,
        address _reputationSystem,
        address _proposalVoting,
        address _identitySystem
    ) Ownable(msg.sender) {
        modelRegistry = SilensModel(_modelRegistry);
        reputationSystem = SilensReputation(_reputationSystem);
        proposalVoting = SilensProposal(_proposalVoting);
        identitySystem = SilensIdentityRegistry(_identitySystem);
        
        emit SystemInitialized(_modelRegistry, _reputationSystem, _proposalVoting, _identitySystem);
    }
    
    function checkAndCreateProposal(uint256 _modelId) external {
        SilensModel.Model memory model = modelRegistry.getModel(_modelId);
        require(model.id != 0, "Model does not exist");
        require(block.timestamp > model.reviewEndTime, "Review period not ended");
        require(modelToProposal[_modelId] == 0, "Proposal already exists");
        
        SilensModel.Review[] memory reviews = modelRegistry.getModelReviews(_modelId);
        uint256 totalSeverity = 0;
        uint256 criticalCount = 0;
        
        for (uint i = 0; i < reviews.length; i++) {
            totalSeverity += reviews[i].severity;
            if (reviews[i].severity >= 4) {
                criticalCount++;
            }
        }
        
        SilensProposal.ProposalType proposalType;
        
        if (reviews.length == 0 || totalSeverity == 0) {
            proposalType = SilensProposal.ProposalType.APPROVE;
        } else {
            uint256 avgSeverity = totalSeverity / reviews.length;
            
            if (criticalCount >= 3 || avgSeverity >= 4) {
                proposalType = SilensProposal.ProposalType.DELIST;
            } else if (avgSeverity >= 3) {
                proposalType = SilensProposal.ProposalType.FLAG;
            } else {
                proposalType = SilensProposal.ProposalType.APPROVE;
            }
        }
        
        uint256 proposalId = proposalVoting.createProposal(_modelId, proposalType);
        modelToProposal[_modelId] = proposalId;
        
        emit AutoProposalCreated(_modelId, proposalId);
    }
    
    function updateModelRegistry(address _newRegistry) external onlyOwner {
        modelRegistry = SilensModel(_newRegistry);
    }
    
    function updateReputationSystem(address _newSystem) external onlyOwner {
        reputationSystem = SilensReputation(_newSystem);
    }
    
    function updateProposalVoting(address _newVoting) external onlyOwner {
        proposalVoting = SilensProposal(_newVoting);
    }
    
    function updateIdentitySystem(address _newIdentity) external onlyOwner {
        identitySystem = SilensIdentityRegistry(_newIdentity);
    }
    
    /**
     * @dev Checks if a reviewer has a verified identity
     * @param _reviewer The reviewer address
     * @return True if the reviewer has a verified identity
     */
    function hasVerifiedIdentity(address _reviewer) external view returns (bool) {
        return identitySystem.hasIdentity(_reviewer);
    }
    
    /**
     * @dev Gets the identity token ID for a reviewer
     * @param _reviewer The reviewer address
     * @return The token ID of the reviewer's identity NFT
     */
    function getReviewerIdentityToken(address _reviewer) external view returns (uint256) {
        return identitySystem.getTokenIdByAddress(_reviewer);
    }
}
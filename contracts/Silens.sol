// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ModelRegistry.sol";
import "./ReputationSystem.sol";
import "./VotingProposal.sol";
import "./IdentityRegistry.sol";

// ==================== SilensCore Contract ====================
contract Silens is Ownable {
    ModelRegistry public modelRegistry;
    ReputationSystem public reputationSystem;
    VotingProposal public proposalVoting;
    IdentityRegistry public identitySystem;
    
    mapping(uint256 => uint256) public modelToProposal;
    
    event SystemInitialized(address modelRegistry, address reputationSystem, address proposalVoting, address identitySystem);
    event AutoProposalCreated(uint256 indexed modelId, uint256 indexed proposalId);
    
    constructor(
        address _modelRegistry,
        address _reputationSystem,
        address _proposalVoting,
        address _identitySystem
    ) Ownable(msg.sender) {
        modelRegistry = ModelRegistry(_modelRegistry);
        reputationSystem = ReputationSystem(_reputationSystem);
        proposalVoting = VotingProposal(_proposalVoting);
        identitySystem = IdentityRegistry(_identitySystem);
        
        emit SystemInitialized(_modelRegistry, _reputationSystem, _proposalVoting, _identitySystem);
    }
    
    function checkAndCreateProposal(uint256 _modelId) external {
        ModelRegistry.Model memory model = modelRegistry.getModel(_modelId);
        require(model.id != 0, "Model does not exist");
        require(block.timestamp > model.reviewEndTime, "Review period not ended");
        require(modelToProposal[_modelId] == 0, "Proposal already exists");
        
        ModelRegistry.Review[] memory reviews = modelRegistry.getModelReviews(_modelId);
        uint256 totalSeverity = 0;
        uint256 criticalCount = 0;
        uint256 positiveReviews = 0;
        uint256 negativeReviews = 0;
        
        for (uint i = 0; i < reviews.length; i++) {
            if (reviews[i].reviewType == ModelRegistry.ReviewType.NEGATIVE) {
                totalSeverity += reviews[i].severity;
                if (reviews[i].severity >= 4) {
                    criticalCount++;
                }
                negativeReviews++;
            } else {
                positiveReviews++;
            }
        }
        
        VotingProposal.ProposalType proposalType;
        
        if (reviews.length == 0) {
            proposalType = VotingProposal.ProposalType.APPROVE;
        } else if (negativeReviews == 0) {
            proposalType = VotingProposal.ProposalType.APPROVE;
        } else {
            uint256 avgSeverity = totalSeverity / negativeReviews;
            
            if (criticalCount >= 3 || avgSeverity >= 4) {
                proposalType = VotingProposal.ProposalType.DELIST;
            } else if (avgSeverity >= 3) {
                proposalType = VotingProposal.ProposalType.FLAG;
            } else {
                proposalType = VotingProposal.ProposalType.APPROVE;
            }
        }
        
        uint256 proposalId = proposalVoting.createProposal(_modelId, proposalType);
        modelToProposal[_modelId] = proposalId;
        
        emit AutoProposalCreated(_modelId, proposalId);
    }
    
    function updateModelRegistry(address _newRegistry) external onlyOwner {
        modelRegistry = ModelRegistry(_newRegistry);
    }
    
    function updateReputationSystem(address _newSystem) external onlyOwner {
        reputationSystem = ReputationSystem(_newSystem);
    }
    
    function updateProposalVoting(address _newVoting) external onlyOwner {
        proposalVoting = VotingProposal(_newVoting);
    }
    
    function updateIdentitySystem(address _newIdentity) external onlyOwner {
        identitySystem = IdentityRegistry(_newIdentity);
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
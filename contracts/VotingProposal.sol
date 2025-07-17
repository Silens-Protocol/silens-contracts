// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ReputationSystem.sol";
import "./ModelRegistry.sol";
import "./IdentityRegistry.sol";

// ==================== ProposalVoting Contract ====================
contract VotingProposal is Ownable, ReentrancyGuard {
    uint256 private _proposalIdCounter;
    
    enum ProposalType { APPROVE, FLAG, DELIST }
    enum ProposalStatus { ACTIVE, PASSED, FAILED, EXECUTED }
    
    struct Proposal {
        uint256 id;
        uint256 modelId;
        ProposalType proposalType;
        ProposalStatus status;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    
    uint256 public votingPeriod = 5 minutes; // demo
    uint256 public quorumPercentage = 10; // demo: lowered for easier testing
    
    ReputationSystem public reputationSystem;
    ModelRegistry public modelRegistry;
    IdentityRegistry public identitySystem;

    address public silens;
    
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed modelId, uint8 proposalType, uint8 status, uint256 forVotes, uint256 againstVotes, uint256 startTime, uint256 endTime, bool executed);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 forVotes, uint256 againstVotes, uint256 timestamp);
    event ProposalExecuted(uint256 indexed proposalId, uint8 result, uint256 forVotes, uint256 againstVotes, uint256 totalGovernanceVoters, uint256 quorum, bool quorumMet, bool majorityWon);
    
    constructor(address _reputationSystem, address _modelRegistry) Ownable(msg.sender) {
        reputationSystem = ReputationSystem(_reputationSystem);
        modelRegistry = ModelRegistry(_modelRegistry);
    }
    
    function setIdentitySystem(address _identitySystem) external onlyOwner {
        identitySystem = IdentityRegistry(_identitySystem);
    }

    function setSilens(address _silens) external onlyOwner {
        silens = _silens;
    }
    
    // Demo function to set custom quorum for testing
    function setQuorumPercentage(uint256 _newQuorumPercentage) external onlyOwner {
        require(_newQuorumPercentage <= 100, "Quorum cannot exceed 100%");
        quorumPercentage = _newQuorumPercentage;
    }
    
    function createProposal(uint256 _modelId, ProposalType _type) external returns (uint256) {
        require(msg.sender == silens, "Only Silens can create proposals");
        _proposalIdCounter++;
        uint256 newProposalId = _proposalIdCounter;
        
        proposals[newProposalId] = Proposal({
            id: newProposalId,
            modelId: _modelId,
            proposalType: _type,
            status: ProposalStatus.ACTIVE,
            forVotes: 0,
            againstVotes: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            executed: false
        });
        
        emit ProposalCreated(newProposalId, _modelId, uint8(_type), uint8(ProposalStatus.ACTIVE), 0, 0, block.timestamp, block.timestamp + votingPeriod, false);
        return newProposalId;
    }
    
    function vote(uint256 _proposalId, bool _support) external nonReentrant {
        require(identitySystem.hasIdentity(msg.sender), "Must have verified identity");
        require(
            reputationSystem.hasRole(msg.sender, reputationSystem.GOVERNANCE_VOTER()),
            "Not eligible to vote"
        );
        
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp <= proposal.endTime, "Voting ended");
        require(!hasVoted[_proposalId][msg.sender], "Already voted");
        
        hasVoted[_proposalId][msg.sender] = true;
        
        if (_support) {
            proposal.forVotes++;
        } else {
            proposal.againstVotes++;
        }
        
        emit VoteCast(_proposalId, msg.sender, _support, proposal.forVotes, proposal.againstVotes, block.timestamp);
    }
    
    function executeProposal(uint256 _proposalId) external nonReentrant {
        require(identitySystem.hasIdentity(msg.sender), "Must have verified identity");
        
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp > proposal.endTime, "Voting not ended");
        require(!proposal.executed, "Already executed");
        
        proposal.executed = true;
        
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        uint256 totalGovernanceVoters = reputationSystem.totalSupply(reputationSystem.GOVERNANCE_VOTER());
        uint256 quorum = (totalGovernanceVoters * quorumPercentage) / 100;
        
        uint8 result;
        bool quorumMet;
        bool majorityWon;

        if (totalVotes >= quorum && proposal.forVotes > proposal.againstVotes) {
            proposal.status = ProposalStatus.PASSED;
            result = uint8(ProposalStatus.PASSED);
            quorumMet = true;
            majorityWon = true;
            if (proposal.proposalType == ProposalType.APPROVE) {
                modelRegistry.updateModelStatus(proposal.modelId, ModelRegistry.ModelStatus.APPROVED);
            } else if (proposal.proposalType == ProposalType.FLAG) {
                modelRegistry.updateModelStatus(proposal.modelId, ModelRegistry.ModelStatus.FLAGGED);
            } else if (proposal.proposalType == ProposalType.DELIST) {
                modelRegistry.updateModelStatus(proposal.modelId, ModelRegistry.ModelStatus.DELISTED);
            }
        } else {
            proposal.status = ProposalStatus.FAILED;
            result = uint8(ProposalStatus.FAILED);
            quorumMet = totalVotes >= quorum;
            majorityWon = proposal.forVotes > proposal.againstVotes;
        }
        
        emit ProposalExecuted(_proposalId, result, proposal.forVotes, proposal.againstVotes, totalGovernanceVoters, quorum, quorumMet, majorityWon);
    }
    
    function getProposal(uint256 _proposalId) external view returns (Proposal memory) {
        return proposals[_proposalId];
    }
}

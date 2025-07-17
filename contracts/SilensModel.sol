// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./SilensReputation.sol";
import "./SilensIdentityRegistry.sol";

// ==================== ModelRegistry Contract ====================
contract SilensModel is Ownable, ReentrancyGuard {
    uint256 private _modelIdCounter;
    
    SilensReputation public reputationSystem;
    SilensIdentityRegistry public identitySystem;
    
    constructor() Ownable(msg.sender) {}
    
    function setReputationSystem(address _reputationSystem) external onlyOwner {
        reputationSystem = SilensReputation(_reputationSystem);
    }
    
    function setIdentitySystem(address _identitySystem) external onlyOwner {
        identitySystem = SilensIdentityRegistry(_identitySystem);
    }
    
    enum ModelStatus { UNDER_REVIEW, APPROVED, FLAGGED, DELISTED }
    
    struct Model {
        uint256 id;
        address submitter;
        string ipfsHash;
        ModelStatus status;
        uint256 submissionTime;
        uint256 reviewEndTime;
        uint256 upvotes;
        uint256 downvotes;
    }
    
    struct Review {
        address reviewer;
        string ipfsHash;
        uint8 severity; // 1-5 (low to critical)
        uint256 timestamp;
    }
    
    mapping(uint256 => Model) public models;
    mapping(uint256 => Review[]) public modelReviews;
    mapping(uint256 => mapping(address => bool)) public hasReviewed;
    
    uint256 public reviewPeriod = 5 minutes; // demo
    
    event ModelSubmitted(uint256 indexed modelId, address indexed submitter, string ipfsHash, uint8 status, uint256 submissionTime, uint256 reviewEndTime);
    event ReviewSubmitted(uint256 indexed modelId, address indexed reviewer, string ipfsHash, uint8 severity, uint256 timestamp);
    event ModelStatusUpdated(uint256 indexed modelId, uint8 newStatus);
    
    function submitModel(
        string memory _ipfsHash
    ) external nonReentrant returns (uint256) {
        require(identitySystem.hasIdentity(msg.sender), "Must have verified identity");
        
        _modelIdCounter++;
        uint256 newModelId = _modelIdCounter;
        
        models[newModelId] = Model({
            id: newModelId,
            submitter: msg.sender,
            ipfsHash: _ipfsHash,
            status: ModelStatus.UNDER_REVIEW,
            submissionTime: block.timestamp,
            reviewEndTime: block.timestamp + reviewPeriod,
            upvotes: 0,
            downvotes: 0
        });
        
        if (address(reputationSystem) != address(0)) {
            reputationSystem.awardModelSubmissionPoints(msg.sender);
        }
        
        emit ModelSubmitted(newModelId, msg.sender, _ipfsHash, 0, block.timestamp, block.timestamp + reviewPeriod);
        return newModelId;
    }
    
    function submitReview(
        uint256 _modelId,
        string memory _ipfsHash,
        uint8 _severity
    ) external {
        require(identitySystem.hasIdentity(msg.sender), "Must have verified identity");
        require(models[_modelId].id != 0, "Model does not exist");
        require(block.timestamp <= models[_modelId].reviewEndTime, "Review period ended");
        require(!hasReviewed[_modelId][msg.sender], "Already reviewed");
        require(_severity >= 1 && _severity <= 5, "Invalid severity");
        
        Review memory newReview = Review({
            reviewer: msg.sender,
            ipfsHash: _ipfsHash,
            severity: _severity,
            timestamp: block.timestamp
        });
        
        modelReviews[_modelId].push(newReview);
        hasReviewed[_modelId][msg.sender] = true;
        
        if (address(reputationSystem) != address(0)) {
            reputationSystem.awardReviewPoints(msg.sender);
        }
        
        emit ReviewSubmitted(_modelId, msg.sender, _ipfsHash, _severity, block.timestamp);
    }
    
    function updateModelStatus(uint256 _modelId, ModelStatus _status) external onlyOwner {
        require(models[_modelId].id != 0, "Model does not exist");
        models[_modelId].status = _status;
        emit ModelStatusUpdated(_modelId, uint8(_status));
    }
    
    function getModel(uint256 _modelId) external view returns (Model memory) {
        return models[_modelId];
    }
    
    function getModelReviews(uint256 _modelId) external view returns (Review[] memory) {
        return modelReviews[_modelId];
    }
    
    function getTotalModels() external view returns (uint256) {
        return _modelIdCounter;
    }
}
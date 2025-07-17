// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./SilensIdentityRegistry.sol";

// ==================== ReputationSystem Contract ====================
contract SilensReputation is ERC1155Supply, Ownable {
    // Badge IDs
    uint256 public constant VERIFIED_REVIEWER = 1;
    uint256 public constant TRUSTED_REVIEWER = 2;
    uint256 public constant GOVERNANCE_VOTER = 3;
    
    mapping(address => uint256) public reputationScores;
    
    uint256 public constant SUBMIT_POINTS = 5;
    
    SilensIdentityRegistry public identitySystem;
    
    event ReputationUpdated(address indexed user, uint256 newScore, uint256 pointsAdded, string reason);
    event BadgeAwarded(address indexed user, uint256 indexed badgeId, string badgeName, uint256 timestamp);
    
    constructor() ERC1155("https://silens-api.up.railway.app/badges/{id}.json") Ownable(msg.sender) {}
    
    function setIdentitySystem(address _identitySystem) external onlyOwner {
        identitySystem = SilensIdentityRegistry(_identitySystem);
    }
    
    function awardModelSubmissionPoints(address _submitter) external onlyOwner {
        reputationScores[_submitter] += SUBMIT_POINTS;
        emit ReputationUpdated(_submitter, reputationScores[_submitter], SUBMIT_POINTS, "Model Submission");
        
        _checkAndAwardBadges(_submitter);
    }

    function awardReviewPoints(address _reviewer) external onlyOwner {
        reputationScores[_reviewer] += SUBMIT_POINTS;
        emit ReputationUpdated(_reviewer, reputationScores[_reviewer], SUBMIT_POINTS, "Review");
        
        _checkAndAwardBadges(_reviewer);
    }
    
    function checkAndAwardVerifiedBadge(address _user) external {
        require(identitySystem.hasIdentity(_user), "User must have identity");
        
        uint256 tokenId = identitySystem.getTokenIdByAddress(_user);
        uint256 verifiedCount = identitySystem.getVerifiedPlatformCount(tokenId);
        
        if (verifiedCount >= 1 && balanceOf(_user, VERIFIED_REVIEWER) == 0) {
            _mint(_user, VERIFIED_REVIEWER, 1, "");
            emit BadgeAwarded(_user, VERIFIED_REVIEWER, "Verified Reviewer", block.timestamp);
        }
    }
        
    function addReputation(address _user, uint256 _points) external onlyOwner {
        reputationScores[_user] += _points;
        emit ReputationUpdated(_user, reputationScores[_user], _points, "Manual Addition");
        
        _checkAndAwardBadges(_user);
    }
    
    function _checkAndAwardBadges(address _user) private {
        uint256 score = reputationScores[_user];
        
        if (score >= 50 && balanceOf(_user, TRUSTED_REVIEWER) == 0) {
            _mint(_user, TRUSTED_REVIEWER, 1, "");
            emit BadgeAwarded(_user, TRUSTED_REVIEWER, "Trusted Reviewer", block.timestamp);
        }
        
        if (score >= 100 && balanceOf(_user, GOVERNANCE_VOTER) == 0) {
            _mint(_user, GOVERNANCE_VOTER, 1, "");
            emit BadgeAwarded(_user, GOVERNANCE_VOTER, "Governance Voter", block.timestamp);
        }
    }
    
    function hasRole(address _user, uint256 _roleId) external view returns (bool) {
        return balanceOf(_user, _roleId) > 0;
    }
    
    // Prevent badge transfers (soulbound)
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal override {
        require(from == address(0) || to == address(0), "Badges are non-transferable");
        super._update(from, to, ids, amounts);
    }
}

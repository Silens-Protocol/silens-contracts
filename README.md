# Silens - AI Safety Platform Smart Contracts

A decentralized governance platform for AI model safety assessment and community-driven decision making.

## 🏗️ Architecture

```
Silens (Main Orchestrator)
├── ModelRegistry (AI Models & Reviews)
├── ReputationSystem (Points & Badges)
├── VotingProposal (Governance)
└── IdentityRegistry (Identity Verification)
```

## 📋 Smart Contracts

### **Silens.sol**
- Main orchestrator contract that coordinates all other contracts
- Automatically creates proposals based on review analysis
- Manages contract addresses and ownership
- Provides identity verification checks

### **ModelRegistry.sol**
- Handles AI model submissions and review management
- Tracks model status (UNDER_REVIEW, APPROVED, FLAGGED, DELISTED)
- Manages review submissions with severity levels (1-5 for negative reviews)
- Requires verified identity for all actions
- 5-minute review period (demo setting)

### **ReputationSystem.sol**
- ERC-1155 badge system (soulbound tokens)
- Automatic reputation point awarding (+5 points for submissions/reviews)
- Badge progression: VERIFIED_REVIEWER → TRUSTED_REVIEWER → GOVERNANCE_VOTER
- Badge thresholds: TRUSTED_REVIEWER (30+ points), GOVERNANCE_VOTER (50+ points)
- Demo function for testing (should be removed in production)

### **VotingProposal.sol**
- Governance voting system with quorum-based decisions
- Automatic proposal creation by Silens contract
- 5-minute voting period (demo setting)
- 10% quorum requirement (demo setting)
- Three proposal types: APPROVE, FLAG, DELIST

### **IdentityRegistry.sol**
- ERC-721 identity NFTs (non-transferable)
- ERC-7231 compliant identity aggregation
- Social platform verification (Twitter, GitHub, LinkedIn, Discord)
- Cryptographic proof of platform ownership
- Cross-platform identity linking

## 🔄 Complete User Flow

### **1. Identity Creation (MANDATORY)**
```
User → Connect Wallet → Create Identity NFT → Verify Social Platforms
```

### **2. Model Submission & Review**
```
User → Submit AI Model (+5 points) → Community Reviews (+5 points each)
```

### **3. Automatic Proposal Creation**
```
Review Period Ends → Silens Analyzes Reviews → Creates Proposal → Governance Voters Decide → Execute Result
```

### **4. Badge Progression**
```
VERIFIED_REVIEWER (1+ social platform) → TRUSTED_REVIEWER (30+ points) → GOVERNANCE_VOTER (50+ points)
```

## 🏆 Badge System

| Badge | Requirements | Benefits |
|-------|-------------|----------|
| **VERIFIED_REVIEWER** | 1+ verified social platform | Identity verification |
| **TRUSTED_REVIEWER** | 30+ reputation points | Community recognition |
| **GOVERNANCE_VOTER** | 50+ reputation points | Can vote on proposals |

## 🔒 Security Features

### **Contract-to-Contract Restrictions**
- Only Silens can create proposals
- Only VotingProposal can update model status
- Only ModelRegistry can award reputation points
- Only contracts with verified identities can perform actions

### **Demo Functions (Remove for Production)**
- `setGovernanceVoter()` in ReputationSystem - allows anyone to become a governance voter
- `setQuorumPercentage()` in VotingProposal - allows owner to change quorum
- Short time periods (5 minutes) for demo purposes

## 📊 Events & Indexing

All contracts emit comprehensive events for Ponder indexing:

### **Silens Events**
- `SystemInitialized` - Contract addresses on deployment
- `AutoProposalCreated` - Automatic proposal creation

### **ModelRegistry Events**
- `ModelSubmitted` - Complete model data
- `ReviewSubmitted` - Complete review data with severity
- `ModelStatusUpdated` - Status changes

### **VotingProposal Events**
- `ProposalCreated` - Complete proposal data
- `VoteCast` - Vote data with updated counts
- `ProposalExecuted` - Execution results with quorum data

### **ReputationSystem Events**
- `ReputationUpdated` - Points and reasons
- `BadgeAwarded` - Badge data with names

### **IdentityRegistry Events**
- `IdentityMinted` - Identity creation
- `PlatformVerified` - Social platform verification
- `SetIdentitiesRoot` - ERC-7231 compliance

## 📁 Project Structure

```
silens-contracts/
├── contracts/
│   ├── Silens.sol              # Main orchestrator
│   ├── ModelRegistry.sol       # Models & reviews
│   ├── ReputationSystem.sol    # Reputation & badges
│   ├── VotingProposal.sol      # Governance voting
│   └── IdentityRegistry.sol    # Identity system
├── ignition/
│   └── modules/
│       └── SilensModule.ts     # Deployment module
├── scripts/
│   └── deploy.ts               # Deployment script
├── test/
│   └── *.test.ts               # Contract tests
└── ponder/                     # Indexing system
    ├── ponder.config.ts        # Ponder configuration
    ├── ponder.schema.ts        # Database schema
    ├── index.ts                # Event handlers
    └── api/
        └── index.ts            # REST API endpoints
```

## ⚠️ Production Considerations

1. **Remove demo functions** before mainnet deployment
2. **Increase time periods** from 5 minutes to appropriate durations
3. **Implement "callable once" logic** for setter functions
4. **Add proper access controls** for governance functions
5. **Test thoroughly** with realistic scenarios
6. **Audit contracts** before mainnet deployment
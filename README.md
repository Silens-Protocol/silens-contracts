# Silens - AI Safety Platform Smart Contracts

A decentralized governance platform for AI model safety assessment and community-driven decision making.

## 🏗️ Architecture

```
SilensCore (Main Orchestrator)
├── ModelRegistry (AI Models & Reviews)
├── ReputationSystem (Points & Badges)
├── ProposalVoting (Governance)
└── SilensIdentity (Identity Verification)
```

## 📋 Smart Contracts

### **SilensCore.sol**
- Main orchestrator contract
- Deploys and connects all other contracts
- Manages contract addresses and ownership

### **ModelRegistry.sol**
- Handles AI model submissions
- Manages review submissions and storage
- Tracks model status (UNDER_REVIEW, APPROVED, FLAGGED, DELISTED)
- Requires verified identity for all actions

### **ReputationSystem.sol**
- ERC-1155 badge system (soulbound tokens)
- Automatic reputation point awarding
- Badge progression: VERIFIED_REVIEWER → TRUSTED_REVIEWER → GOVERNANCE_VOTER
- Points for model submissions (+5) and reviews (+5)

### **ProposalVoting.sol**
- Governance voting system
- Automatic proposal creation based on review analysis
- Quorum-based voting (20% of governance voters)
- Owner-only proposal creation, community voting

### **SilensIdentity.sol**
- ERC-721 identity NFTs (non-transferable)
- ERC-7231 compliant identity aggregation
- Social platform verification with cryptographic proof
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

### **3. Governance Decision**
```
Review Period Ends → Owner Creates Proposal → Governance Voters Decide → Execute Result
```

### **4. Badge Progression**
```
VERIFIED_REVIEWER (1+ social platform) → TRUSTED_REVIEWER (50+ points) → GOVERNANCE_VOTER (100+ points)
```

## 🏆 Badge System

| Badge | Requirements | Benefits |
|-------|-------------|----------|
| **VERIFIED_REVIEWER** | 1+ verified social platform | Identity verification |
| **TRUSTED_REVIEWER** | 50+ reputation points | Community recognition |
| **GOVERNANCE_VOTER** | 100+ reputation points | Can vote on proposals |

## 🔐 Access Control

| Action | Identity Required | Badge Required | Owner Only |
|--------|------------------|----------------|------------|
| Create Identity | ❌ | ❌ | ❌ |
| Verify Platform | ✅ | ❌ | ❌ |
| Submit Model | ✅ | ❌ | ❌ |
| Submit Review | ✅ | ❌ | ❌ |
| Create Proposal | ✅ | ❌ | ✅ |
| Vote on Proposal | ✅ | GOVERNANCE_VOTER | ❌ |
| Execute Proposal | ✅ | ❌ | ❌ |

## 📊 Events & Indexing

All contracts emit comprehensive events for Ponder indexing:

### **ModelRegistry Events**
- `ModelSubmitted` - Complete model data
- `ReviewSubmitted` - Complete review data
- `ModelStatusUpdated` - Status changes

### **ProposalVoting Events**
- `ProposalCreated` - Complete proposal data
- `VoteCast` - Vote data with updated counts
- `ProposalExecuted` - Execution results with quorum data

### **ReputationSystem Events**
- `ReputationUpdated` - Points and reasons
- `BadgeAwarded` - Badge data with names

### **SilensIdentity Events**
- `IdentityMinted` - Identity creation
- `PlatformVerified` - Social platform verification

## 📁 Project Structure

```
silens-contracts/
├── contracts/
│   ├── SilensCore.sol          # Main orchestrator
│   ├── ModelRegistry.sol       # Models & reviews
│   ├── ReputationSystem.sol    # Reputation & badges
│   ├── ProposalVoting.sol      # Governance voting
│   └── SilensIdentity.sol      # Identity system
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
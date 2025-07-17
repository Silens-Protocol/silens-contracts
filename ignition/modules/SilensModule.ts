import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("SilensModule", (m) => {
  const modelRegistry = m.contract("ModelRegistry");
  const reputationSystem = m.contract("ReputationSystem");
  const silensIdentity = m.contract("IdentityRegistry");
  
  const proposalVoting = m.contract("VotingProposal", [
    reputationSystem,
    modelRegistry
  ]);
  
  const silensCore = m.contract("Silens", [
    modelRegistry,
    reputationSystem,
    proposalVoting,
    silensIdentity
  ]);
  
  m.call(proposalVoting, "setSilens", [silensCore]);
  m.call(modelRegistry, "setReputationSystem", [reputationSystem]);
  m.call(modelRegistry, "setIdentitySystem", [silensIdentity]);
  m.call(proposalVoting, "setIdentitySystem", [silensIdentity]);
  m.call(reputationSystem, "setIdentitySystem", [silensIdentity]);
  m.call(modelRegistry, "setProposalContract", [proposalVoting]);
  m.call(reputationSystem, "setModelRegistry", [modelRegistry]);
    
  return {
    modelRegistry,
    reputationSystem,
    proposalVoting,
    silensIdentity,
    silensCore
  };
});

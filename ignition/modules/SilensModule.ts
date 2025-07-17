import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("SilensModule", (m) => {
  const modelRegistry = m.contract("SilensModel");
  const reputationSystem = m.contract("SilensReputation");
  const silensIdentity = m.contract("SilensIdentityRegistry");
  
  const proposalVoting = m.contract("SilensProposal", [
    reputationSystem,
    modelRegistry
  ]);
  
  const silensCore = m.contract("Silens", [
    modelRegistry,
    reputationSystem,
    proposalVoting,
    silensIdentity
  ]);
  
  m.call(modelRegistry, "setReputationSystem", [reputationSystem]);
  m.call(modelRegistry, "setIdentitySystem", [silensIdentity]);
  m.call(proposalVoting, "setIdentitySystem", [silensIdentity]);
  m.call(reputationSystem, "setIdentitySystem", [silensIdentity]);
  
  m.call(modelRegistry, "transferOwnership", [proposalVoting]);
  m.call(reputationSystem, "transferOwnership", [modelRegistry]);
  
  return {
    modelRegistry,
    reputationSystem,
    proposalVoting,
    silensIdentity,
    silensCore
  };
});

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("SilensModule", (m) => {
  const modelRegistry = m.contract("SilensModelRegistry");
  const reputationSystem = m.contract("SilensReputationSystem");
  const silensIdentity = m.contract("SilensIdentity");
  
  const proposalVoting = m.contract("SilensProposalVoting", [
    reputationSystem,
    modelRegistry
  ]);
  
  const silensCore = m.contract("SilensCore", [
    modelRegistry,
    reputationSystem,
    proposalVoting,
    silensIdentity
  ]);
  
  m.call(modelRegistry, "setReputationSystem", [reputationSystem]);
  m.call(modelRegistry, "setIdentitySystem", [silensIdentity]);
  m.call(proposalVoting, "setIdentitySystem", [silensIdentity]);
  m.call(reputationSystem, "setIdentitySystem", [silensIdentity]);
  
  m.call(modelRegistry, "transferOwnership", [silensCore]);
  
  return {
    modelRegistry,
    reputationSystem,
    proposalVoting,
    silensIdentity,
    silensCore
  };
});

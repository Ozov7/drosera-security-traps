// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/traps/MEVSandwichDetector.sol";
import "../src/traps/GovernanceAttackMonitor.sol";
import "../src/traps/OracleManipulationDetector.sol";
import "../src/responders/SecurityResponder.sol";

/**
 * @title DeployScript
 * @notice Deploys all Drosera security traps and responder
 * @dev Use: forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast
 */
contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("🚀 Starting deployment of Drosera Security Traps...");
        console.log("================================================");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy the unified responder first
        console.log("\n📦 Deploying Security Responder...");
        SecurityResponder responder = new SecurityResponder();
        console.log("✅ Responder deployed at: %s", address(responder));
        
        // 2. Deploy MEV Sandwich Detector
        console.log("\n🔍 Deploying MEV Sandwich Detector...");
        MEVSandwichDetector mevTrap = new MEVSandwichDetector();
        console.log("✅ MEV Trap deployed at: %s", address(mevTrap));
        
        // 3. Deploy Governance Attack Monitor
        console.log("\n🏛️ Deploying Governance Attack Monitor...");
        GovernanceAttackMonitor govTrap = new GovernanceAttackMonitor();
        console.log("✅ Governance Trap deployed at: %s", address(govTrap));
        
        // 4. Deploy Oracle Manipulation Detector
        console.log("\n📊 Deploying Oracle Manipulation Detector...");
        OracleManipulationDetector oracleTrap = new OracleManipulationDetector();
        console.log("✅ Oracle Trap deployed at: %s", address(oracleTrap));
        
        vm.stopBroadcast();
        
        // Generate drosera.toml configuration
        console.log("\n🎯 ===== Drosera Configuration ===== ");
        console.log("\n# MEV Sandwich Detector");
        console.log("[trap.mev_sandwich]");
        console.log("address = \"%s\"", address(mevTrap));
        console.log("response_contract = \"%s\"", address(responder));
        console.log("response_function = \"handleMEVAlert\"");
        console.log("block_sample_size = 3");
        
        console.log("\n# Governance Attack Monitor");
        console.log("[trap.governance_monitor]");
        console.log("address = \"%s\"", address(govTrap));
        console.log("response_contract = \"%s\"", address(responder));
        console.log("response_function = \"handleGovernanceAlert\"");
        console.log("block_sample_size = 10");
        
        console.log("\n# Oracle Manipulation Detector");
        console.log("[trap.oracle_detector]");
        console.log("address = \"%s\"", address(oracleTrap));
        console.log("response_contract = \"%s\"", address(responder));
        console.log("response_function = \"handleOracleAlert\"");
        console.log("block_sample_size = 2");
        
        console.log("\n📝 Deployment complete!");
        console.log("👉 Update your drosera.toml with the addresses above");
        console.log("👉 Register traps with Drosera Network");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/traps/GovernanceAttackMonitor.sol";

contract GovernanceAttackMonitorTest is Test {
    GovernanceAttackMonitor monitor;
    
    function setUp() public {
        monitor = new GovernanceAttackMonitor();
    }
    
    function testConstants() public {
        assertEq(
            monitor.GOVERNANCE_TOKEN(), 
            address(0xc00e94Cb662C3520282E6f5717214004A7f26888),
            "COMP token address should match"
        );
        assertEq(
            monitor.GOVERNOR(), 
            address(0xc0Da02939E1441F497fd74F78cE7Decb17B66529),
            "Compound Governor address should match"
        );
        assertEq(monitor.VOTING_POWER_SPIKE_BPS(), 1000, "10% spike threshold");
        assertEq(monitor.MAX_DELEGATION_CHANGES(), 5, "Max delegation changes");
    }
    
    function testPlannerSafety() public {
        // Test empty data
        bytes[] memory emptyData = new bytes[](0);
        (bool shouldTrigger, bytes memory response) = monitor.evaluateResponse(emptyData);
        
        assertFalse(shouldTrigger, "Should not trigger on empty data");
        assertEq(response.length, 0, "Response should be empty");
    }
    
    function testConstructor() public view {
        // Just ensure it deploys without revert
        address(monitor);
    }
    
    function testEvaluateResponseOnBlock100() public {
        // Create dummy data for block 100
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encode(uint256(100), uint256(block.timestamp));
        
        (bool shouldTrigger, bytes memory response) = monitor.evaluateResponse(data);
        
        // Should trigger on block 100 (100 % 100 == 0)
        assertTrue(shouldTrigger, "Should trigger on block 100");
        assertGt(response.length, 0, "Response should not be empty");
        
        // Decode and verify alert structure
        GovernanceAttackMonitor.GovernanceAlert memory alert = 
            abi.decode(response, (GovernanceAttackMonitor.GovernanceAlert));
        
        assertEq(alert.proposalId, 100, "Proposal ID should match block number");
        assertEq(alert.alertType, "VOTING_POWER_SPIKE", "Alert type should match");
        assertEq(alert.votingPowerChange, 1500, "Voting power change should be 15%");
    }
    
    function testEvaluateResponseOnBlock101() public {
        // Create dummy data for block 101
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encode(uint256(101), uint256(block.timestamp));
        
        (bool shouldTrigger, bytes memory response) = monitor.evaluateResponse(data);
        
        // Should NOT trigger on block 101 (101 % 100 != 0)
        assertFalse(shouldTrigger, "Should not trigger on block 101");
        assertEq(response.length, 0, "Response should be empty");
    }
    
    function testCollectFunction() public view {
        // Test that collect() returns something without reverting
        bytes memory result = monitor.collect();
        assertGt(result.length, 0, "Collect should return non-empty data");
        
        // Verify it can be decoded
        (uint256 blockNum, uint256 timestamp) = abi.decode(result, (uint256, uint256));
        assertGt(blockNum, 0, "Block number should be positive");
        assertGt(timestamp, 0, "Timestamp should be positive");
    }
}

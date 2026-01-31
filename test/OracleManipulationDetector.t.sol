// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/traps/OracleManipulationDetector.sol";

contract OracleManipulationDetectorTest is Test {
    OracleManipulationDetector detector;
    
    function setUp() public {
        detector = new OracleManipulationDetector();
    }
    
    function testConstants() public view {
        assertEq(
            detector.CHAINLINK_ETH_USD(), 
            address(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419),
            "Chainlink ETH/USD address should match"
        );
        assertEq(
            detector.UNISWAP_V3_POOL(), 
            address(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640),
            "Uniswap V3 pool address should match"
        );
        assertEq(detector.MAX_DEVIATION_BPS(), 500, "5% deviation threshold");
        assertEq(detector.MIN_VOLUME_ETH(), 100 ether, "100 ETH minimum volume");
    }
    
    function testPlannerSafety() public view {
        // Test empty data
        bytes[] memory emptyData = new bytes[](0);
        (bool shouldTrigger, bytes memory response) = detector.evaluateResponse(emptyData);
        
        assertFalse(shouldTrigger, "Should not trigger on empty data");
        assertEq(response.length, 0, "Response should be empty");
    }
    
    function testConstructor() public view {
        // Just ensure it deploys without revert
        address(detector);
    }
    
    function testCollectFunction() public view {
        // Test that collect() returns something without reverting
        bytes memory result = detector.collect();
        assertGt(result.length, 0, "Collect should return non-empty data");
        
        // Verify it can be decoded
        (uint256 chainlinkPrice, uint256 uniswapPrice, uint256 blockNum) = 
            abi.decode(result, (uint256, uint256, uint256));
        
        assertEq(chainlinkPrice, 2500 * 1e8, "Chainlink price should be $2500");
        assertEq(uniswapPrice, 2550 * 1e18, "Uniswap price should be $2550");
        assertGt(blockNum, 0, "Block number should be positive");
    }
    
    function testNoDeviation() public {
        // Test with no price deviation (should not trigger)
        uint256 chainlinkPrice = 2500 * 1e8; // $2500
        uint256 uniswapPrice = 2500 * 1e18; // Also $2500 (no deviation)
        uint256 blockNumber = 100;
        
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encode(chainlinkPrice, uniswapPrice, blockNumber);
        
        (bool shouldTrigger, bytes memory response) = detector.evaluateResponse(data);
        
        assertFalse(shouldTrigger, "Should not trigger with 0% deviation");
        assertEq(response.length, 0, "Response should be empty");
    }
    
    function testHighDeviation() public {
        // Test with 10% deviation (should trigger)
        uint256 chainlinkPrice = 2500 * 1e8; // $2500
        uint256 uniswapPrice = 2750 * 1e18; // $2750 (10% higher)
        uint256 blockNumber = 100;
        
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encode(chainlinkPrice, uniswapPrice, blockNumber);
        
        (bool shouldTrigger, bytes memory response) = detector.evaluateResponse(data);
        
        assertTrue(shouldTrigger, "Should trigger with 10% deviation (>5% threshold)");
        assertGt(response.length, 0, "Response should not be empty");
        
        // Decode and verify alert
        OracleManipulationDetector.OracleAlert memory alert = 
            abi.decode(response, (OracleManipulationDetector.OracleAlert));
        
        assertEq(alert.oracleSource, detector.CHAINLINK_ETH_USD(), "Should alert on Chainlink");
        assertEq(alert.reportedPrice, chainlinkPrice, "Reported price should match");
        assertEq(alert.referencePrice, uniswapPrice, "Reference price should match");
        assertGt(alert.deviationBps, 500, "Deviation should be >5%");
    }
}

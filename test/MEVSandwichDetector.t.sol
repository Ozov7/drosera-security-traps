// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/traps/MEVSandwichDetector.sol";

contract MEVSandwichDetectorTest is Test {
    MEVSandwichDetector detector;
    
    function setUp() public {
        detector = new MEVSandwichDetector();
    }
    
    function testConstants() public {
        assertEq(detector.UNISWAP_POOL(), address(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640));
        assertEq(detector.MIN_PRICE_IMPACT_BPS(), 50);
        assertEq(detector.MIN_PROFIT_ETH(), 0.1 ether);
    }
    
    function testPlannerSafety() public {
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
    
    function testInsufficientSwaps() public {
        // Create dummy swap data with only 2 swaps
        MEVSandwichDetector.SwapData[] memory swaps = new MEVSandwichDetector.SwapData[](2);
        swaps[0] = MEVSandwichDetector.SwapData({
            sender: address(0x1),
            amount0: 1000,
            amount1: -1000,
            blockNumber: 100,
            timestamp: block.timestamp,
            isExactInput: true
        });
        swaps[1] = MEVSandwichDetector.SwapData({
            sender: address(0x2),
            amount0: -1000,
            amount1: 1000,
            blockNumber: 100,
            timestamp: block.timestamp,
            isExactInput: false
        });
        
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encode(swaps);
        
        (bool shouldTrigger, ) = detector.evaluateResponse(data);
        assertFalse(shouldTrigger, "Should not trigger with only 2 swaps");
    }
}

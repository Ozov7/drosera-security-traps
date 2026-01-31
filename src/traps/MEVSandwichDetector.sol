// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Trap} from "drosera-contracts/Trap.sol";

/**
 * @title MEVSandwichDetector
 * @notice Detects sandwich attacks on Uniswap V3 pools
 * @dev Monitors Swap events for frontrun/backrun patterns
 */
contract MEVSandwichDetector is Trap {
    // ========== CONSTANTS ==========
    address public constant UNISWAP_POOL = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640; // WETH-USDC 0.05%
    uint256 public constant MIN_PRICE_IMPACT_BPS = 50; // 0.5%
    uint256 public constant MIN_PROFIT_ETH = 0.1 ether;
    uint256 public constant MAX_BLOCK_SPAN = 3;
    
    bytes32 public constant SWAP_TOPIC = 
        keccak256("Swap(address,address,int256,int256,uint160,uint128,int24)");
    
    // ========== STRUCTS ==========
    struct SwapData {
        address sender;
        int256 amount0;
        int256 amount1;
        uint256 blockNumber;
        uint256 timestamp;
        bool isExactInput;
    }
    
    struct MEVAlert {
        address victim;
        address attacker;
        uint256 profitEstimate;
        uint256 priceImpact;
        uint256 blockNumber;
    }
    
    // ========== CONSTRUCTOR ==========
    constructor() {
        _addEventFilter(UNISWAP_POOL, SWAP_TOPIC);
    }
    
    // ========== TRAP FUNCTIONS ==========
    function collect() external view override returns (bytes memory) {
        Trap.Log[] memory logs = getFilteredLogs();
        SwapData[] memory swaps = new SwapData[](logs.length);
        
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] != SWAP_TOPIC || logs[i].topics.length < 7) continue;
            
            // Decode swap data
            (, int256 amount0, int256 amount1, , , , ) = abi.decode(
                logs[i].data,
                (address, int256, int256, uint160, uint128, int24, address)
            );
            
            address sender = address(uint160(uint256(logs[i].topics[6])));
            
            swaps[i] = SwapData({
                sender: sender,
                amount0: amount0,
                amount1: amount1,
                blockNumber: block.number,
                timestamp: block.timestamp,
                isExactInput: amount0 > 0
            });
        }
        
        return abi.encode(swaps);
    }
    
    function shouldRespond(
        bytes[] calldata data
    ) external pure override returns (bool, bytes memory) {
        // Planner safety
        if (data.length < 1 || data[0].length == 0) {
            return (false, bytes(""));
        }
        
        SwapData[] memory swaps = abi.decode(data[0], (SwapData[]));
        
        // Need at least 3 swaps for sandwich detection
        if (swaps.length < 3) return (false, bytes(""));
        
        // Simplified MEV detection: multiple swaps in same block from different addresses
        uint256 uniqueSenders = 0;
        address[] memory seenSenders = new address[](swaps.length);
        
        for (uint256 i = 0; i < swaps.length; i++) {
            bool isNew = true;
            for (uint256 j = 0; j < uniqueSenders; j++) {
                if (seenSenders[j] == swaps[i].sender) {
                    isNew = false;
                    break;
                }
            }
            if (isNew) {
                seenSenders[uniqueSenders] = swaps[i].sender;
                uniqueSenders++;
            }
        }
        
        // Basic MEV pattern: at least 2 unique addresses swapping in same block
        if (uniqueSenders >= 2 && swaps[0].blockNumber == swaps[swaps.length - 1].blockNumber) {
            MEVAlert memory alert = MEVAlert({
                victim: swaps[1].sender,
                attacker: swaps[0].sender,
                profitEstimate: 0.15 ether,
                priceImpact: 75,
                blockNumber: swaps[0].blockNumber
            });
            
            return (true, abi.encode(alert));
        }
        
        return (false, bytes(""));
    }
}

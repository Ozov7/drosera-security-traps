// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Simple Trap interface for compilation
interface ITrap {
    struct Log {
        bytes32[] topics;
        bytes data;
    }
    
    // Functions that traps MUST implement
    function collect() external view returns (bytes memory);
    function evaluateResponse(bytes[] calldata data) external view returns (bool, bytes memory);
}

// Simple abstract contract that traps inherit from
abstract contract Trap is ITrap {
    // These are internal helpers that traps can use
    function _addEventFilter(address, bytes32) internal virtual {}
    function getFilteredLogs() internal view virtual returns (Log[] memory) {
        return new Log[](0);
    }
}

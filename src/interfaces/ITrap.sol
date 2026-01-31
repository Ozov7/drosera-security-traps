
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal Trap interface for compilation
// Will be replaced with real drosera-contracts later
interface ITrap {
    struct Log {
        bytes32[] topics;
        bytes data;
    }
    
    function _addEventFilter(address, bytes32) external;
    function getFilteredLogs() external view returns (Log[] memory);
}

abstract contract Trap is ITrap {
    function collect() external virtual view returns (bytes memory);
    function shouldRespond(bytes[] calldata data) external virtual pure returns (bool, bytes memory);
    
    // Minimal implementations for compilation
    function _addEventFilter(address, bytes32) internal virtual {}
    function getFilteredLogs() internal view virtual returns (Log[] memory) {
        return new Log[](0);
    }
}

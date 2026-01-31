// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal Trap interface for compilation
// Will be replaced with real drosera-contracts in production

abstract contract ITrap {
    struct Log {
        bytes32[] topics;
        bytes data;
    }
    
    function _addEventFilter(address, bytes32) external virtual;
    function getFilteredLogs() external view virtual returns (Log[] memory);
    function collect() external virtual view returns (bytes memory);
    function shouldRespond(bytes[] calldata data) external virtual pure returns (bool, bytes memory);
}

contract Trap is ITrap {
    // Minimal implementations for compilation
    function _addEventFilter(address, bytes32) internal override {}
    
    function getFilteredLogs() internal view override returns (Log[] memory) {
        return new Log[](0);
    }
    
    function collect() external view override returns (bytes memory) {
        return "";
    }
    
    function shouldRespond(bytes[] calldata) external pure override returns (bool, bytes memory) {
        return (false, "");
    }
}

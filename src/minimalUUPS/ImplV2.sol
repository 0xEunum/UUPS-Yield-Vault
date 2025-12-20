// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
contract ImplV2 {
    address public owner;
    uint256 public value;
    uint256 public newValue;

    function setValue(uint256 _v) external {
        value = _v;
    }

    function setNewValue(uint256 _newValue) external {
        newValue = _newValue;
    }

    function upgradeTo(address newImpl) external {
        require(msg.sender == owner, "not owner");

        // EIP-1967 slot
        // keccak256("eip1967.proxy.implementation") - 1
        bytes32 slot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

        assembly {
            sstore(slot, newImpl)
        }
    }
}

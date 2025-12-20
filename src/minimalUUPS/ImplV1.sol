// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// 0x5FbDB2315678afecb367f032d93F642f64180aa3
contract ImplV1 {
    address public owner;
    uint256 public value;

    // $ cast calldata "initialize(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (Wallet address of owner)
    // Output -> 0xc4d66de8000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266
    function initialize(address _owner) external {
        require(owner == address(0), "already init");
        owner = _owner;
    }

    function setValue(uint256 _v) external {
        value = _v;
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

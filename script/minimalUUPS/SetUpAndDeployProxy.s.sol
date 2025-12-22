// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {SimpleUUPSProxy} from "src/minimalUUPS/SimpleUUPSProxy.sol";
import {ImplV1} from "src/minimalUUPS/ImplV1.sol";
import {ImplV2} from "src/minimalUUPS/ImplV2.sol";

// 0x5FbDB2315678afecb367f032d93F642f64180aa3
contract SetUpAndDeployProxy is Script {
    address constant ANVIL_DEFAULT_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function run() external returns (address, address) {
        address implV1 = deployImplV1();
        address proxy = deployAndSetUpProxy(implV1);

        return (proxy, implV1);
    }

    function deployImplV1() public returns (address) {
        vm.startBroadcast();

        ImplV1 implV1 = new ImplV1();

        vm.stopBroadcast();

        return address(implV1);
    }

    function deployAndSetUpProxy(address _implV1) public returns (address) {
        vm.startBroadcast();

        bytes memory initData = abi.encodeWithSignature("initialize(address)", ANVIL_DEFAULT_ADDRESS);
        // bytes memory initData = abi.encodeWithSignature("initialize(address)", tx.origin);
        // bytes memory initData = abi.encodeWithSignature("initialize(address)", msg.sender);

        SimpleUUPSProxy proxy = new SimpleUUPSProxy(_implV1, initData);

        vm.stopBroadcast();

        return address(proxy);
    }

    function upgradeToV2(address _proxy) external returns (address) {
        vm.startBroadcast();

        ImplV2 implV2 = new ImplV2();

        vm.stopBroadcast();

        ImplV1(_proxy).upgradeTo(address(implV2));

        return address(implV2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {SimpleUUPSProxy} from "src/minimalUUPS/SimpleUUPSProxy.sol";
import {ImplV1} from "src/minimalUUPS/ImplV1.sol";
import {ImplV2} from "src/minimalUUPS/ImplV2.sol";

interface IProxy {
    function owner() external returns (address);
    function value() external returns (uint256);
    function newValue() external returns (uint256);
    function initialize(address) external;
    function setValue(uint256) external;
    function setNewValue(uint256) external;
    function upgradeTo(address) external;
}

contract SetUpAndDeployProxy is Script {
    SimpleUUPSProxy proxy;
    ImplV1 implV1;
    ImplV2 implV2;

    function run() external returns (SimpleUUPSProxy, ImplV1) {
        implV1 = deployImplV1();
        proxy = deployAndSetUpProxy(implV1);

        return (proxy, implV1);
    }

    function deployImplV1() public returns (ImplV1) {
        vm.startBroadcast();

        implV1 = new ImplV1();

        vm.stopBroadcast();

        return implV1;
    }

    function deployAndSetUpProxy(ImplV1 _implV1) public returns (SimpleUUPSProxy) {
        vm.startBroadcast();

        bytes memory initData = abi.encodeWithSignature("initialize(address)", msg.sender);
        // bytes memory initData = abi.encodeWithSignature("initialize(address)", tx.origin);

        proxy = new SimpleUUPSProxy(address(_implV1), initData);

        vm.stopBroadcast();

        return proxy;
    }

    function upgradeToV2(SimpleUUPSProxy _proxy) external returns (ImplV2) {
        vm.startBroadcast();

        implV2 = new ImplV2();

        vm.stopBroadcast();

        IProxy(address(_proxy)).upgradeTo(address(implV2));

        return implV2;
    }
}

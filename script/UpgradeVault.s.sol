// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

import {VaultV1} from "src/VaultV1.sol";
import {VaultV2} from "src/VaultV2.sol";

contract UpgradeVault is Script {
    function upgradeVault(address _proxy) public returns (address) {
        vm.startBroadcast();

        VaultV2 vaultV2 = new VaultV2();

        VaultV1 proxyAddress = VaultV1(_proxy);

        // bytes memory initData = abi.encodeWithSignature("initializeV2()");
        bytes memory initData = abi.encodeWithSelector(VaultV2.initializeV2.selector);

        proxyAddress.upgradeToAndCall(address(vaultV2), initData);

        vm.stopBroadcast();

        return address(proxyAddress);
    }
}

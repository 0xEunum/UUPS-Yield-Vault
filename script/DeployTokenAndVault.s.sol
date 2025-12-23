// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {YldToken} from "src/YldToken.sol";
import {VaultV1} from "src/VaultV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {Script} from "forge-std/Script.sol";

contract DeployTokenAndVault is Script {
    YldToken token;

    function run() public returns (address, address) {
        address yldToken = deployToken();
        address proxy = deployVaultAndSetProxy();

        return (yldToken, proxy);
    }

    function deployToken() public returns (address) {
        vm.startBroadcast();
        token = new YldToken();
        vm.stopBroadcast();
        return address(token);
    }

    function deployVaultAndSetProxy() public returns (address) {
        vm.startBroadcast();
        VaultV1 vaultV1 = new VaultV1();
        if (address(token) == address(0)) {
            token = YldToken(deployToken());
        }
        // bytes memory initData = abi.encodeWithSignature("initialize(address)", address(token));
        // Or this to call initialize and set owner and specified varialbes
        bytes memory initData = abi.encodeWithSelector(VaultV1.initialize.selector, address(token));
        ERC1967Proxy proxy = new ERC1967Proxy(address(vaultV1), initData);
        token.setProxy(address(proxy));
        vm.stopBroadcast();

        return address(proxy);
    }
}

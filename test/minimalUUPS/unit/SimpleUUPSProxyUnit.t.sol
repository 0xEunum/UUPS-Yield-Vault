// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SetUpAndDeployProxy} from "script/minimalUUPS/SetUpAndDeployProxy.s.sol";
import {ImplV1} from "src/minimalUUPS/ImplV1.sol";

contract SimpleUUPSProxyUnit is Test {
    SetUpAndDeployProxy deployer;

    address proxy;
    address implV1;
    address implV2;

    address constant ANVIL_DEFAULT_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() external {
        deployer = new SetUpAndDeployProxy();
        (proxy, implV1) = deployer.run();
    }

    function testOwnerIsInitialize() public view {
        address expectedOwner = ImplV1(proxy).owner();
        assertEq(ANVIL_DEFAULT_ADDRESS, expectedOwner);
    }

    function testInitializeFailWhenOwnerIsSet() public {
        vm.expectRevert();
        ImplV1(proxy).initialize(address(1));
    }

    function testValueIsSetToZero() public view {
        uint256 expectedValue = 0;
        uint256 value = ImplV1(proxy).value();

        assertEq(expectedValue, value);
    }

    function testSetValueExpected() public {
        uint256 expectedValue = 0;
        uint256 value = ImplV1(proxy).value();

        assertEq(expectedValue, value);

        ImplV1(proxy).setValue(20);

        uint256 expectedNewValue = ImplV1(proxy).value();

        assertEq(expectedNewValue, 20);
    }

    // function testUpgradeToV2Works() public {
    //     ImplV1(proxy).setValue(10);

    //     vm.prank(ANVIL_DEFAULT_ADDRESS);
    //     implV2 = deployer.upgradeToV2(proxy);

    //     uint256 valueAfterUpgrade = ImplV2(proxy).value();
    //     assertEq(valueAfterUpgrade, 10);
    // }
}

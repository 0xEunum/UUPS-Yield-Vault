// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {VaultV1} from "src/VaultV1.sol";
import {VaultV2} from "src/VaultV2.sol";
import {YldToken} from "src/YldToken.sol";

import {DeployTokenAndVault} from "script/DeployTokenAndVault.s.sol";
import {UpgradeVault} from "script/UpgradeVault.s.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract VaultUUPS is Test {
    DeployTokenAndVault deployer;
    UpgradeVault upgrader;

    VaultV1 vaultV1;
    VaultV2 vaultV2;

    address token;
    address proxy;

    address owner = makeAddr("owner");
    address user = makeAddr("user");
    address user2 = makeAddr("user2");

    uint256 constant DEPOSIT_AMOUNT = 1e18;

    function setUp() public {
        // Deploy scripts
        deployer = new DeployTokenAndVault();
        upgrader = new UpgradeVault();

        // Deploy token and proxy
        // Setup impl as VaultV1
        (token, proxy) = deployer.run();

        // Transfer ownerships from scripts to owner
        vm.startPrank(YldToken(token).owner());

        YldToken(token).transferOwnership(owner);
        VaultV1(proxy).transferOwnership(owner);

        vm.stopPrank();
    }

    function testOwnerships() public view {
        address expectedTokenOwner = YldToken(token).owner();
        assertEq(expectedTokenOwner, owner);

        address expectedProxyOwner = VaultV1(proxy).owner();
        assertEq(expectedProxyOwner, owner);
    }

    function testYldTokenIsSet() public view {
        address yldToken = address(VaultV1(proxy).yld());
        assertEq(token, yldToken);
    }

    function testVaultV2RatePerWeek() public view {
        assertEq(100, VaultV1(proxy).ratePerWeek());
    }

    // DEPOSIT TESTS
    function testUserDeposits() public {
        uint256 tokenBeforeDeposit = YldToken(token).balanceOf(user);
        uint256 beforeDepositBalance = VaultV1(proxy).principal(user);
        assertEq(tokenBeforeDeposit, beforeDepositBalance);

        uint256 userLastUpdate = VaultV1(proxy).lastUpdate(user);
        assertEq(0, userLastUpdate);

        vm.prank(user);
        vm.expectRevert();
        VaultV1(proxy).deposit(0);

        vm.prank(user);
        VaultV1(proxy).deposit(DEPOSIT_AMOUNT);

        uint256 tokenAfterDeposit = YldToken(token).balanceOf(user);
        assertEq(tokenAfterDeposit, DEPOSIT_AMOUNT);

        uint256 afterDepositBalance = VaultV1(proxy).principal(user);
        assertEq(afterDepositBalance, DEPOSIT_AMOUNT);

        uint256 currentBlockTimeStamp = block.timestamp;
        assertEq(currentBlockTimeStamp, VaultV1(proxy).lastUpdate(user));
    }

    // WITHDRAW TESTS
    function testUserWithdraws() public {
        vm.prank(user);
        vm.expectRevert();
        VaultV1(proxy).withdraw();

        vm.prank(user);
        VaultV1(proxy).deposit(DEPOSIT_AMOUNT);

        vm.warp(block.timestamp + 2 weeks);
        vm.roll(block.number + 100);

        // CORRECT: 1% per week × 2 weeks = 2% total interest
        uint256 expectedInterest = (DEPOSIT_AMOUNT * 100 * 2) / 10_000; // 2e16
        uint256 expectedTotal = DEPOSIT_AMOUNT + expectedInterest; // 1.02e18

        uint256 userBalanceBefore = YldToken(token).balanceOf(user);
        vm.prank(user);
        VaultV1(proxy).withdraw();

        uint256 tokenBalanceAfterWithdraw = YldToken(token).balanceOf(user);
        assertEq(expectedTotal, tokenBalanceAfterWithdraw);

        assertEq(userBalanceBefore, tokenBalanceAfterWithdraw - expectedInterest);
    }

    function test_InterestMatchesFormula() public {
        vm.prank(user);
        VaultV1(proxy).deposit(DEPOSIT_AMOUNT);

        vm.warp(block.timestamp + 2 weeks);

        // Manually calculate expected interest
        uint256 weeksPassed = 2;
        uint256 expectedInterest = (DEPOSIT_AMOUNT * VaultV1(proxy).ratePerWeek() * weeksPassed) / 10_000;

        uint256 balanceBefore = YldToken(token).balanceOf(user);
        vm.prank(user);
        VaultV1(proxy).withdraw();

        assertEq(DEPOSIT_AMOUNT + expectedInterest, YldToken(token).balanceOf(user));
        assertEq(DEPOSIT_AMOUNT + expectedInterest, balanceBefore + expectedInterest);
        assertEq(0, VaultV1(proxy).principal(user)); // Principal cleared
    }

    function testUpgradeVaultV2() public {
        uint256 ratePerWeekVaultV1 = VaultV1(proxy).ratePerWeek();
        assertEq(100, ratePerWeekVaultV1);

        console.log("Proxy Owner Before", VaultV1(proxy).owner());
        console.log("Actual Owner", owner);

        vm.prank(owner);
        VaultV1(proxy).transferOwnership(msg.sender);

        console.log("Proxy Owner After", VaultV1(proxy).owner());
        console.log("Address this", address(this));

        address newProxy = upgrader.upgradeVault(proxy);

        assertEq(proxy, newProxy);

        uint256 ratePerWeekVaultV2 = VaultV2(proxy).ratePerWeek();
        assertEq(200, ratePerWeekVaultV2);
    }

    function testVaultV1StateVariablesPresists() public {
        vm.prank(user);
        VaultV1(proxy).deposit(DEPOSIT_AMOUNT);
        vm.warp(block.timestamp + 5 weeks);
        vm.roll(block.number + 100);

        uint256 beforeUpgradeBalance = YldToken(token).balanceOf(user);
        assertEq(DEPOSIT_AMOUNT, beforeUpgradeBalance);

        vm.prank(owner);
        VaultV1(proxy).transferOwnership(msg.sender);

        address newProxy = upgrader.upgradeVault(proxy);

        uint256 afterUpgradeBalance = YldToken(token).balanceOf(user);
        assertEq(beforeUpgradeBalance, afterUpgradeBalance);

        vm.prank(user);
        VaultV2(newProxy).withdraw();

        // // CORRECT: 1% per week × 5 weeks = 5% total interest
        // uint256 expectedInterest = (DEPOSIT_AMOUNT * 100 * 5) / 10_000; // 2e16
        // uint256 expectedTotal = DEPOSIT_AMOUNT + expectedInterest; //

        // console.log("interest", expectedInterest);
        // console.log("total", expectedTotal);

        // uint256 balanceAfterAccuredInterest = YldToken(token).balanceOf(user);
        // console.log("Balance after", balanceAfterAccuredInterest);
        // assertEq(expectedInterest + DEPOSIT_AMOUNT, balanceAfterAccuredInterest);
        // // assertEq(expectedTotal, balanceAfterAccuredInterest);
    }
}

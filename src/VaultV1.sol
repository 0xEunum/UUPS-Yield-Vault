// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {YldToken} from "./YldToken.sol";

contract VaultV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    error ZERO_AMOUNT();
    error NO_DEPOSIT();

    YldToken public yld;

    // 100 = 1% (basis points)
    uint256 public ratePerWeek;

    mapping(address user => uint256 balance) public principal;
    mapping(address user => uint256 timeStamp) public lastUpdate;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _yld) external initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        yld = YldToken(_yld);
        ratePerWeek = 100; // 1%
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    // ------------------
    // Core logic
    // ------------------

    function deposit(uint256 amount) external {
        if (amount == 0) revert ZERO_AMOUNT();

        _accrue(msg.sender);

        principal[msg.sender] += amount;
        lastUpdate[msg.sender] = block.timestamp;

        yld.mint(msg.sender, amount);
    }

    function withdraw() external {
        uint256 userPrincipal = principal[msg.sender];
        if (userPrincipal == 0) revert NO_DEPOSIT();

        uint256 interest = _accrue(msg.sender);

        principal[msg.sender] = 0;
        lastUpdate[msg.sender] = 0;

        yld.mint(msg.sender, interest);
        // principal already minted at deposit
        // so total balance becomes principal + interest
    }

    // ------------------
    // Interest logic
    // ------------------

    function _accrue(address user) internal returns (uint256) {
        uint256 last = lastUpdate[user];
        if (last == 0) return 0;

        uint256 weeksPassed = (block.timestamp - last) / 1 weeks;
        if (weeksPassed == 0) return 0;

        uint256 interest = (principal[user] * ratePerWeek * weeksPassed) / 10_000;

        lastUpdate[user] = block.timestamp;

        return interest;
    }
}

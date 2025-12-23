// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {VaultV1} from "./VaultV1.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract VaultV2 is VaultV1 {
    function initializeV2() external reinitializer(2) {
        ratePerWeek = 200; // 2%
    }
}

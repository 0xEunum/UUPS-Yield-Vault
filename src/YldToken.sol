// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract YldToken is ERC20, Ownable {
    error YldToken__Unauthoraized();
    error YldToken__ZeroAddress();
    error YldToken__ProxyNotSet();

    address public proxy;

    constructor() ERC20("Yield Token", "YLD") Ownable(msg.sender) {}

    modifier onlyProxy() {
        if (proxy == address(0)) revert YldToken__ProxyNotSet();
        if (msg.sender != proxy) revert YldToken__Unauthoraized();
        _;
    }

    function setProxy(address _proxy) external onlyOwner {
        if (_proxy == address(0)) revert YldToken__ZeroAddress();
        proxy = _proxy;
    }

    function mint(address to, uint256 amount) external onlyProxy {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyProxy {
        _burn(from, amount);
    }
}

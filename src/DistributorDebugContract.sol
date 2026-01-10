// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// this contract is only used for debug

contract DistributionDebugContract is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;

    event Distributed(address indexed to, uint256 amount);

    constructor(IERC20 _token, address initialOwner) Ownable(initialOwner) {
        require(address(_token) != address(0), "token=0");
        token = _token;
    }

    function distribute(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "to=0");
        require(amount > 0, "amount=0");
        token.safeTransfer(to, amount);
        emit Distributed(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * SideQuestToken (SQT)
 * - Fixed supply is 10 000 000
 * - No mint function exposed after deployment (non-inflationary)
 */
contract SideQuestToken is ERC20 {
    uint8 private constant _DECIMALS = 6;

    constructor(address treasury, uint256 initialSupply)
        ERC20("SideQuest Token", "SQT")
    {
        require(treasury != address(0), "treasury=0");
        require(initialSupply > 0, "supply=0");

        _mint(treasury, initialSupply);
    }

    function decimals() public pure override returns (uint8) {
        return _DECIMALS;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

import {SideQuestToken} from "../src/SideQuestToken.sol";
import {SideQuestSC} from "../src/SideQuestSC.sol";
import {DistributionDebugContract} from "../src/DistributorDebugContract.sol";

contract Deploy is Script {
    function run() external {
        address treasury = vm.envAddress("TREASURY");
        uint256 initialSupply = vm.envUint("INITIAL_SUPPLY");
        uint256 minCreateAmount = vm.envUint("MIN_CREATE_AMOUNT");

        vm.startBroadcast();
        SideQuestToken token = new SideQuestToken(treasury, initialSupply);
        new SideQuestSC(token, minCreateAmount);
        new DistributionDebugContract(token, treasury);
        vm.stopBroadcast();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {SideQuestToken} from "../src/SideQuestToken.sol";
import {SideQuestSC} from "../src/SideQuestSC.sol";
import {DistributionDebugContract} from "../src/DistributorDebugContract.sol";

contract SideQuestTest is Test {
    SideQuestToken private token;
    SideQuestSC private sc;
    DistributionDebugContract private debug;

    address private treasury = vm.addr(1);
    address private creator = vm.addr(2);
    address private solver = vm.addr(3);
    address private recipient = vm.addr(4);

    uint256 private initialSupply = 10_000_000 * 1e6;
    uint256 private minCreateAmount = 1_000 * 1e6;

    function setUp() public {
        token = new SideQuestToken(treasury, initialSupply);
        sc = new SideQuestSC(token, minCreateAmount);
        debug = new DistributionDebugContract(token, treasury);

        vm.prank(treasury);
        token.transfer(creator, 5_000 * 1e6);

        vm.prank(treasury);
        token.transfer(address(debug), 1_000 * 1e6);
    }

    function testCreateCommitRevealFlow() public {
        uint256 rewardAmount = 2_000 * 1e6;
        string memory passcode = "secret-pass";
        bytes32 solverSalt = keccak256(abi.encodePacked("salt"));

        bytes32 answerCommitment = keccak256(abi.encodePacked(passcode));
        bytes32 contentHash = keccak256(abi.encodePacked("content"));

        vm.startPrank(creator);
        token.approve(address(sc), rewardAmount);
        uint256 id = sc.createChallenge(rewardAmount, answerCommitment, contentHash);
        vm.stopPrank();

        bytes32 solverCommit = keccak256(abi.encodePacked(id, solver, passcode, solverSalt));

        vm.prank(solver);
        sc.commitSolve(id, solverCommit);

        uint256 solverBalanceBefore = token.balanceOf(solver);
        vm.prank(solver);
        sc.revealSolve(id, passcode, solverSalt);

        (, , uint256 storedReward, , , SideQuestSC.Status status, address winner) = sc.challenges(id);
        assertEq(storedReward, rewardAmount);
        assertEq(uint8(status), uint8(SideQuestSC.Status.Claimed));
        assertEq(winner, solver);
        assertEq(token.balanceOf(solver), solverBalanceBefore + rewardAmount);
    }

    function testDebugDistributionOwnerOnly() public {
        uint256 amount = 250 * 1e6;

        vm.prank(treasury);
        debug.distribute(recipient, amount);
        assertEq(token.balanceOf(recipient), amount);

        vm.prank(creator);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, creator)
        );
        debug.distribute(recipient, amount);
    }
}

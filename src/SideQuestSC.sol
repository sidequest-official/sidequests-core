pragma solidity ^0.8.20;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SideQuestSC is ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum Status {
        None,
        Active,
        Claimed
    }

    struct Challenge {
        uint256 id;
        address creator;
        uint256 rewardAmount;      // paid in SideQuestToken
        bytes32 answerCommitment;  // keccak256(passcode)
        bytes32 contentHash;
        Status status;
        address winner;
    }

    IERC20 public immutable sideQuestToken;
    uint256 public immutable minCreateAmount;

    uint256 public nextChallengeId = 1;
    mapping(uint256 => Challenge) public challenges;

    // solverCommits[id][solver] = keccak256(id, solver, passcode, solverSalt)
    mapping(uint256 => mapping(address => bytes32)) public solverCommits;

    event ChallengeCreated(
        uint256 indexed id,
        address indexed creator,
        uint256 rewardAmount,
        bytes32 answerCommitment,
        bytes32 contentHash
    );

    event SolveCommitted(uint256 indexed id, address indexed solver, bytes32 solverCommit);
    event ChallengeClaimed(uint256 indexed id, address indexed winner);

    constructor(IERC20 _sideQuestToken, uint256 _minCreateAmount) {
        require(address(_sideQuestToken) != address(0), "token=0");
        require(_minCreateAmount > 0, "min=0");
        sideQuestToken = _sideQuestToken;
        minCreateAmount = _minCreateAmount;
    }

    // Creator escrows rewardAmount tokens into the contract
    function createChallenge(
        uint256 rewardAmount,
        bytes32 answerCommitment,
        bytes32 contentHash
    ) external returns (uint256 id) {
        require(rewardAmount >= minCreateAmount, "reward < min");

        // Pull tokens into escrow
        sideQuestToken.safeTransferFrom(msg.sender, address(this), rewardAmount);

        id = nextChallengeId++;

        challenges[id] = Challenge({
            id: id,
            creator: msg.sender,
            rewardAmount: rewardAmount,
            answerCommitment: answerCommitment,
            contentHash: contentHash,
            status: Status.Active,
            winner: address(0)
        });

        emit ChallengeCreated(id, msg.sender, rewardAmount, answerCommitment, contentHash);
    }

    function commitSolve(uint256 challengeId, bytes32 solverCommit) external {
        Challenge storage c = challenges[challengeId];
        require(c.status == Status.Active, "not active");
        require(solverCommits[challengeId][msg.sender] == bytes32(0), "already committed");

        solverCommits[challengeId][msg.sender] = solverCommit;
        emit SolveCommitted(challengeId, msg.sender, solverCommit);
    }

    function revealSolve(
        uint256 challengeId,
        string calldata passcode,
        bytes32 solverSalt
    ) external nonReentrant {
        Challenge storage c = challenges[challengeId];
        require(c.status == Status.Active, "not active");

        bytes32 committed = solverCommits[challengeId][msg.sender];
        require(committed != bytes32(0), "no commit");

        // Commit must match what solver committed earlier (bound to msg.sender)
        bytes32 expectedCommit = keccak256(abi.encodePacked(challengeId, msg.sender, passcode, solverSalt));
        require(expectedCommit == committed, "bad commit");

        // Passcode must match challenge answer commitment
        bytes32 expectedAnswer = keccak256(abi.encodePacked(passcode));
        require(expectedAnswer == c.answerCommitment, "bad passcode");

        // Effects
        c.status = Status.Claimed;
        c.winner = msg.sender;
        delete solverCommits[challengeId][msg.sender];

        // Payout
        sideQuestToken.safeTransfer(msg.sender, c.rewardAmount);

        emit ChallengeClaimed(challengeId, msg.sender);
    }
}

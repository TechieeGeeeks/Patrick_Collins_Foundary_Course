// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

/* Checks - Effects - Interations Design pattern (why?)=> {To prevent Re entrancy attack}
// It Means while writing functionalities first we have to write 
// 1. Checks => What checks we need for this functions? if not fillfilled revert
// 2. Effects => After checks start the compitation part. Effect Contract
// 3. Interactions -> Lastly we do interactions with contract(Outside)
*/

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

/**
 * @title A sample Raffle Contract
 * @author Swayam Karle
 * @notice This contract is for creating a simple raffle
 * @dev Implements Chainlink VRFv2
 */

/* Imports Here */
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2 {
    // Errors
    // Convention ContractName__ErrorHint__ERROR
    error Raffle__notEnoughEth_ERROR();
    error Raffle__notEnoughTimePassed_ERROR();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    /* Enums here */
    // Enum => We needed it cause suppose that we want to pick a winner
    // at that time we dont want someone to enter in lottery so what we can
    // do is can keep track of current activities via Enum variable which can have only two values
    enum RaffleState {
        OPEN, // It will be 0
        CALCULATING // It will be 1
    }

    // State Variables
    address payable[] private s_players; // This address can get paid
    uint256 private s_lastTimeStamp;

    /* Constant variables which are always constant never change */
    uint16 private constant REUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    /* Immutable variables */
    // Using Immutable to save gas will have value in it once deployed
    uint256 private immutable i_entranceFee;

    // @dev Duration of the lottery in seconds
    uint256 private immutable i_interval;

    // @dev Immutable variable for coordinator contract address
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    // @dev Immutable variable for gasLane Keyhash
    bytes32 private immutable i_gasLane;

    // @dev Immutable variable for subscription id
    uint64 private immutable i_subscriptionId;

    // @dev Immutable variable for subscription id
    uint32 private immutable i_callBackGasLimit;

    // @dev Immutable variable for recent winner
    address private s_recentWinner;

    // @dev Immutable variable for Raffle State
    RaffleState private s_raffleState;

    // Events Here
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event reuestedRaffleWinner(uint256 indexed requesId);

    constructor(
        uint256 fees,
        uint256 interval,
        address vrfCoordinatorAddr,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callBackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorAddr) {
        i_entranceFee = fees;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorAddr);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callBackGasLimit = callBackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        /* costs More gas require(msg.value>= i_entranceFee, "Not Enough ETH Sent"); */
        if (msg.value < i_entranceFee) {
            revert Raffle__notEnoughEth_ERROR();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        // Storage Update here
        s_players.push(payable(msg.sender));
        // Whenever We do storage update we should emit event
        // Why? 1) Makes Migration of contracts easier 2) To index data on frontend

        // Emitting here
        emit EnteredRaffle(msg.sender); // Basically when someone enters raffle we will get notify over here
    }

    /**
     * @dev This is the function that the chainlink automation node will check if its time to perform an upkeep or not
     *
     * The Following things should be true to return upkeepNeeded = true cause
     * 1. The time interval has passed between raffle runs
     * 2. The raffle should be in OPEN state
     * 3. The contract has ETH (Enough Players)
     * 4. The subscription should be funded with LINKS(IMPLICIT)
     * @return upKeepNeeded = true
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upKeepNeeded, bytes memory /*performData */) {
        // 1. check to see if The time interval has passed between raffle runs
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;

        // 2. check to see if raffle is in OPEN state or not
        bool isOPen = s_raffleState == RaffleState.OPEN;

        // 3. check to see if contract has ETH (Enough Players)
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upKeepNeeded = (timeHasPassed && isOPen && hasBalance && hasPlayers);
        return (upKeepNeeded, "0x0"); // 0x0 tells that its blank
    }

    // This function will be responsible for picking winner
    function performUpkeep(bytes calldata /* performData */) external {
        // Checks
        /* Things to remember
    // 1. Get a Random Number
    // 2. Use the random Number to pick a player
    // 3. Pick winner should get automatically called (Not manually) After particular time.
    */

        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Raffle__UpkeepNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        // check to see if enough time has passed or not
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert Raffle__notEnoughTimePassed_ERROR(); // Patrick Havent refracted it yet
        }

        // Effects

        s_raffleState = RaffleState.CALCULATING;
        // Will revert if subscription is not set and funded.

        // Interactions
        /* For getting random number we perform two transactions 
        1. Requesting a Random Number
        2. Getting the Random Number <- its a callback function 
        */
        /* uint256 requestId = */uint256 requestId=  i_vrfCoordinator.requestRandomWords( // each chain has its own chainlink coordinator address where you can request the random number via contract address
            i_gasLane, // gas lane
            i_subscriptionId, // The id which you funded with link tokens to make this request
            REUEST_CONFIRMATIONS, // The no of blocks confiemstions that you want to wait before actually receiving number
            i_callBackGasLimit, // To make sure taht we dont spread extra money on gas
            NUM_WORDS // No of random numbers you need
        );
        emit reuestedRaffleWinner(requestId);
    }

    // As we are overriding interface(Just telling us to implment this function) this function will be called by vrf coordinator in our contract only
    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        // Now you recieved the request id and random numbers both you can use them now
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0); // The small (0) tells that we gonna start at address 0
        s_lastTimeStamp = block.timestamp;
        emit PickedWinner(winner);
        (bool sucess, ) = winner.call{value:address(this).balance}("");
        if (!sucess) {
            revert Raffle__TransferFailed();
        }
    }

    /** Getter Function for accessing fees */
    function getEntraceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    /** Getter Function for accessing Raffle state */
    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    /** Getter Function for accessing Raffle state */
    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getPlayersLength() external view returns (uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

}

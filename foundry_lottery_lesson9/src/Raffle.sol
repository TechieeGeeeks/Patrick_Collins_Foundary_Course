// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
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

contract Raffle{

    // Errors
    // Convention ContractName__ErrorHint__ERROR
    error Raffle__notEnoughEth_ERROR();
    error Raffle_notEnoughTimePassed_ERROR();

    // State Variables
    address payable[] private s_players; // This address can get paid
    uint256 private s_lastTimeStamp;

    /* Constant variables which are always constant never change */
    uint8 private constant REUEST_CONFIRMATIONS= 3; 
    uint8 private constant NUM_WORDS = 1;
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

    // Events Here
    event EnteredRaffle(address indexed player);

    // On deployment of contract the contract owner should provide Fees required to enter in lottery and a thresold time so that winner can be picked.
    constructor(uint256 fees, uint256 interval, address vrfCoordinatorAddr, bytes32 gasLane, uint64 subscriptionId, uint32 callBackGasLimit){
        i_entranceFee= fees;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorAddr);
        i_gasLane= gasLane;
        i_subscriptionId = subscriptionId;
        i_callBackGasLimit = callBackGasLimit;
    }

    function enterRaffle() external payable{
       /* costs More gas require(msg.value>= i_entranceFee, "Not Enough ETH Sent"); */
       if(msg.value < i_entranceFee){
        revert Raffle__notEnoughEth_ERROR();
       }
       // Storage Update here
       s_players.push(payable(msg.sender));
       // Whenever We do storage update we should emit event
       // Why? 1) Makes Migration of contracts easier 2) To index data on frontend

        // Emitting here
        emit EnteredRaffle(msg.sender); // Basically when someone enters raffle we will get notify over here

    }

    // This function will be responsible for picking winner
    function pickWinner() external {
    /* Things to remember
    // 1. Get a Random Number
    // 2. Use the random Number to pick a player
    // 3. Pick winner should get automatically called (Not manually) After particular time.
    */

    // check to see if enough time has passed or not
    if((block.timestamp - s_lastTimeStamp) < i_interval){
        revert Raffle_notEnoughTimePassed_ERROR(); // Patrick Havent refracted it yet
    }
    /* For getting random number we perform two transactions 
        1. Requesting a Random Number
        2. Getting the Random Number <- its a callback function 
    */

   // Will revert if subscription is not set and funded.
    uint256 requestId = i_vrfCoordinator.requestRandomWords( // each chain has its own chainlink coordinator address where you can request the random number via contract address 
        i_gasLane, // gas lane
        i_subscriptionId, // The id which you funded with link tokens to make this request 
        REUEST_CONFIRMATIONS, // The no of blocks confiemstions that you want to wait before actually receiving number 
        i_callBackGasLimit, // To make sure taht we dont spread extra money on gas
        NUM_WORDS // No of random numbers you need
    );

    }

    /** Getter Function  */
    function getEntraceFee() external view returns(uint256){
        return i_entranceFee;
    }
}
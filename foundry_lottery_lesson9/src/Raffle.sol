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
contract Raffle{

    // Errors
    // Convention ContractName__ErrorHint__ERROR
    error Raffle__notEnoughEth_ERROR();
    error Raffle_notEnoughTimePassed_ERROR();

    // State Variables
    address payable[] private s_players; // This address can get paid
    uint256 private s_lastTimeStamp;

    // Using Immutable to save gas will have value in it once deployed
    uint256 private immutable i_entranceFee;

    // @dev Duration of the lottery in seconds
    uint256 private immutable i_interval;

    // Events Here
    event EnteredRaffle(address indexed player);

    // On deployment of contract the contract owner should provide Fees required to enter in lottery and a thresold time so that winner can be picked.
    constructor(uint256 fees, uint256 interval){
        i_entranceFee= fees;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
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

    }

    /** Getter Function  */
    function getEntraceFee() external view returns(uint256){
        return i_entranceFee;
    }
}
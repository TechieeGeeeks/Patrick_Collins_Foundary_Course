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

    // State Varables
    address payable[] private s_players; // This address can get paid

    // Using Immutable to save gas will have value in it once deployed
    uint256 private immutable i_entranceFee;

    

    constructor(uint256 fees){
        i_entranceFee= fees;
    }

    function enterRaffle() external payable{
       /* costs More gas require(msg.value>= i_entranceFee, "Not Enough ETH Sent"); */
       if(msg.value < i_entranceFee){
        revert Raffle__notEnoughEth_ERROR();
       }
       s_players.push(payable(msg.sender));
    }

    function pickWinner() public{

    }

    /** Getter Function  */
    function getEntraceFee() external view returns(uint256){
        return i_entranceFee;
    }
}
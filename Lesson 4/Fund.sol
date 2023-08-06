// Get Funds From Users
// Withdraw Funds
// Set A minimum Funding Value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {PriceConverter} from "./PriceConverter.sol";

using PriceConverter for uint256;

// Custom Errors [Optimization Trick 3]
// Remember its declared outside cause its rule
// In require statement we spend alot of gas by using string as a reverting message 
// cause string is basically a array of bytes we can save gas by using alternative method
// By using custom errors
// Execution cost before using constant 7,62,397 
// Execution cost after using constant 7,37,367  
// 35k gas difference on deploying and 2k gas cost on calling externally.
error notOwner();

contract FundMe{

// Constant [Optimization Trick 1]
// Execution cost before using constant 8,05,927 
// Execution cost after using constant 7,85,976 
// 20k gas difference on deploying and 2k gas cost on calling externally.
// For Auditing practices Constant Variables are declared in all Caps Like Below
    uint256 public constant MIN_USD = 5 * 1e18;

// Immutable [Optimization Trick 2]  
// Execution cost before using immutable 7,85,976  
// Execution cost after using constant 7,62,397 
// 20k diffence on deploying time and 2k on every call
// Immutable when variables are declared on a line and assigned values on other line then we need to
// declare them immutable not constant 
// Its like take 1st declared value and it will be constant
    address public immutable i_owner;


    address[] public funders;
    mapping (address funder =>uint256 amountFunded) public addressToFundedAmount;

    modifier onlyOwner(){
        // New way of usig modifiers instead of require statments
        if(msg.sender!= i_owner){
            revert notOwner();
        }
        _;
    }

    constructor(){
        i_owner = msg.sender;
        }

    function fund() public payable{
        // Allow Users To Send Money 
        // Have A Minimum Amout of Dollar Spent 
        require(msg.value.getConversionRate() >= MIN_USD,"Donate Atleast 1 ether ");// 1e18 = 1ETH
        funders.push(msg.sender); 
        addressToFundedAmount[msg.sender] += msg.value; 
    }

    function Withdraw() public payable onlyOwner{
        // OnlyOnwer modifiers require statement wiuld get executed first
        for(uint256 funderIndex = 0 ; funderIndex < funders.length ; funderIndex++){
            // Reseting their donation to 0
            addressToFundedAmount[funders[funderIndex]] = 0;
        }
        // reseting array to 0 as we dont need track of historical funders we want new funders
        funders = new address[](0);

        // msg.sender is a address of type payable means he can recieve funds from contract
        // Using transfer method fails above 2300 gas and returns erro
        // payable( msg.sender).transfer(address(this).balance);
        // If th tranasaction fails then it reverts and throws error


        // Using Send Method fails above 2300 gas and returns boolean
        // bool sendSuccess =  payable( msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // If transaction fails it return boolean but dosent revert the
        // transaction so we need extra check of require(sendSuccess, "Send failed");

        //Using Call Method SuperPowerFull recommended way to send and receive funds
        // ("") This is used to call function fromm any other contract
        // {} If Youre using it as a money sending function then you have to set money by assigning money to value: parameter from {}
        // It returns Two variables 
        // 1) Bool = which tells whether the function call was successfull or not
        // 2) bytes = If your calling function from any other contract by using call{}("") and that function returns data 
        // then the data will be captured in this bytes
        // As it is memory we have to use memory keyword
        (bool callSuccess, /*bytes memory dataReturned*/) = payable( msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
    }

// Reffer to FalBack.sol File 
    receive() external payable{
        fund();
    }

    fallback() external payable{
        fund();
    }
    
}
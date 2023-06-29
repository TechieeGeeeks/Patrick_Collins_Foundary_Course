//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMetest is Test{
    //initiating a fake user for testing which has no money
    address USER  = makeAddr("user");

    uint256 constant userBalance = 10e18;

    uint256 constant ETH_AMOUNT = 5e18;

    /*uint256 constant GAS_PRICE =1;*/

     FundMe fundMe; //Initializing the fundMe with type FundMe
    function setUp() external{
        // Sending value to the fake user in deploy of function
        vm.deal(USER,userBalance);

        // This setUp is function which always runs first 
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();       
    }

    function testMinDollarIsFive() public{
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public{
       // console.log("So we are deploying contract via address ", msg.sender );
       // console.log("This contract (FundMeTest) is deploying FundMe ","So this ", address(this), " contract address should be the owner of FundMe ");
        assertEq(fundMe.getOwner(),msg.sender);
        console.log(msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public{
        assertEq(fundMe.getVersion(),4);
    }

    function testFundFailWithoutEnoughETH() public{
        vm.expectRevert(); // Its like telling test that next line should get revert
        //Its just like telling assert(this tx fails, revert); Means if transaction dosent get failed then revert
        fundMe.fund{value: 1000}();
    }

    modifier funded(){
        vm.prank(USER); // Using that fake user for next transactions simply next transaction will be send by this user
        // Sending Enough funds
        fundMe.fund{value: ETH_AMOUNT}();
        _;
    }

    function testUpdateOfDataStructuresOnSuccess() public funded{
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, ETH_AMOUNT);
    }

    function testAddrFunderInArray() public funded{
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testWithdrawOnlyOwner() public funded{
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded{
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner()); // we will be owner by this
        fundMe.withdraw();

        //Assert 
        uint256 remainingOwnerBalance = fundMe.getOwner().balance;
        uint256 remainingFundMeBalance = address(fundMe).balance;
        assertEq(remainingFundMeBalance, 0);
        assertEq(remainingOwnerBalance, startingOwnerBalance+startingFundMeBalance);
    }

    function testWithdrawWithMultipleFunders() public funded{
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i<numberOfFunders; i++ ){
            // create new address + give that address money using hoax
            hoax(address(i), userBalance);
            // fund the contratc via that address
            fundMe.fund{value:ETH_AMOUNT}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        /*
        uint256 gasStart = gasleft(); //1000 gas send with transaction
        vm.txGasPrice(GAS_PRICE);
        */
        vm.prank(fundMe.getOwner()); // we will be owner by this
        fundMe.withdraw(); // It used 200 gas

        /*
        uint256 gasEnd = gasleft(); // 800 gas left by the end of tranasaction

        uint256 gasUsed = (gasStart-gasEnd) * tx.gasprice; // amount of gas used will 800
        console.log(gasUsed);
        */
        //Assert 
        uint256 remainingOwnerBalance = fundMe.getOwner().balance;
        uint256 remainingFundMeBalance = address(fundMe).balance;
        assertEq(remainingFundMeBalance, 0);
        assertEq(remainingOwnerBalance, startingOwnerBalance+startingFundMeBalance);
    }

    function testWithdrawWithMultipleFundersOptimize() public funded{
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i<numberOfFunders; i++ ){
            hoax(address(i), userBalance);
            fundMe.fund{value:ETH_AMOUNT}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        vm.prank(fundMe.getOwner()); 
        fundMe.cheaperWithDraw(); 
        uint256 remainingOwnerBalance = fundMe.getOwner().balance;
        uint256 remainingFundMeBalance = address(fundMe).balance;
        assertEq(remainingFundMeBalance, 0);
        assertEq(remainingOwnerBalance, startingOwnerBalance+startingFundMeBalance);
    }

    function testRemainingUserBalance() public{
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i<numberOfFunders; i++ ){
            // create new address + give that address money using hoax
            hoax(address(i), userBalance);
            // fund the contratc via that address
            fundMe.fund{value:ETH_AMOUNT}();
        } 
        //assert 
        for(uint160 i = startingFunderIndex; i<numberOfFunders; i++ ){
            // Making sure that users only spending 5e18 eth while funding contract
            assertEq(address(i).balance, 5e18);
        } 
    }
}
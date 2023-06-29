//SPDX-License-Identifier: MIT

// This to check whether any contract can call the functions from it or not?
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundme, WithdrawFundme} from "../../script/Interactions.s.sol";

contract IntegrationTest is Test{
    //initiating a fake user for testing which has no money
    address USER  = address(1);
    uint256 constant userBalance = 10e18;
    uint256 constant ETH_AMOUNT = 5e18;
    FundMe public fundMe;
    /*uint256 constant GAS_PRICE =1;*/
    function setUp() external{
        DeployFundMe deployer = new DeployFundMe();
        fundMe= deployer.run();
        vm.deal(USER,userBalance);
    }

    function testUserCanFundInteractions() public{
        FundFundme fundFundme = new FundFundme();
        fundFundme.fundFundMe(address(fundMe));

        WithdrawFundme withdrawFundme = new WithdrawFundme();
        withdrawFundme.withDrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0);

    }
}
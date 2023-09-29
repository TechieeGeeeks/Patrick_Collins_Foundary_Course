// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "lib/forge-std/src/Test.sol";
import {StandardToken} from "../src/StandardToken.sol";
import {DeployStandardToken} from "../script/DeployStandardToken.s.sol";

contract StandardTokenTest is Test{

    StandardToken public standardToken;
    DeployStandardToken public deployer;

    uint256 public constant PLAYER_BALANCE = 100 ether;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    function setUp() public{
        deployer = new DeployStandardToken();
        standardToken = deployer.run();
        
        vm.prank(msg.sender);
        standardToken.transfer(bob,PLAYER_BALANCE);
    }

    function testBobBalance() public{
        assertEq(standardToken.balanceOf(bob),PLAYER_BALANCE);
    }

    function testAliceBalance() public{
        assertEq(standardToken.balanceOf(alice),0);
    }

    function testAllowances() public{
        uint256 initalAllowance = 1000;

        vm.prank(bob);
        standardToken.approve(alice,initalAllowance);

        vm.prank(alice);
        standardToken.transferFrom(bob, alice, 999);
        assertEq(standardToken.balanceOf(alice),999);
        assertEq(standardToken.balanceOf(bob),PLAYER_BALANCE-999);
        assertEq(standardToken.allowance(bob,alice),1);
    }

}
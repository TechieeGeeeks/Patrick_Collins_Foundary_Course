// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script, Test{

    function createSubscriptionUsingConfig() public returns(uint64){
        HelperConfig helperConfig = new HelperConfig();
        (,,address vrfCoordinatorAddr,,,,) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinatorAddr);
    }

    function createSubscription(address vrfCoordinator) public returns(uint64){
        console.log("Creating subscription on ChainId", block.chainid);
        vm.startBroadcast();
        uint64 subId =  VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your Sub Id is", subId);
        return subId;
    }

    function run() external returns(uint64){
        return createSubscriptionUsingConfig();
    }
}

contract FundSubsciption is Test{
    uint96 public constant FUND_AMOUNT = 3 ether;

    function run() external{
        fundSubsciptionUsingConfig();
    }

    function fundSubsciptionUsingConfig() public{
        HelperConfig helperConfig = new HelperConfig();
        (,,address vrfCoordinatorAddr,,uint64 subId, ,address linkToken) = helperConfig.activeNetworkConfig();
        fundSubsciption( vrfCoordinatorAddr, subId, linkToken);
    }

    function fundSubsciption (address vrfCoordinatorAddr, uint64 subId,address linkToken) public{
        console.log("Funding Subscription: ", subId);
        console.log("Using Coordinator: ", vrfCoordinatorAddr);
        console.log("On Chain: ", block.chainid);
        if(block.chainid==31337){
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinatorAddr).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        }else{
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoordinatorAddr, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

}

contract AddConsumer is Script{
    function run() external{
        address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffle);
    }

    function addConsumerUsingConfig(address _raffle) public{
        HelperConfig helperConfig = new HelperConfig();
        (,,address vrfCoordinatorAddr,,uint64 subId, , ) = helperConfig.activeNetworkConfig();
        addConsumerInteractions(_raffle, vrfCoordinatorAddr, subId);
    }

    function addConsumerInteractions(address _raffle, address _vrfCoordinatorAddr, uint64 _subId) public{
        console.log("Adding Consumer Contract:", _raffle);
        console.log("Using crfCooridinator", _vrfCoordinatorAddr);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(_vrfCoordinatorAddr).addConsumer(_subId, _raffle);
        vm.stopBroadcast();
    }
}
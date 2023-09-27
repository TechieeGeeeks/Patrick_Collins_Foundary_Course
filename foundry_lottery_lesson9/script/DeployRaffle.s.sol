// SPDX-License-Identifier: MIT

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubsciption, AddConsumer} from "../script/Interactions.s.sol";

pragma solidity ^0.8.18;

contract DeployRaffle is Script{
    function run() external returns(Raffle, HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
       (uint256 fees,
        uint256 interval,
        address vrfCoordinatorAddr,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callBackGasLimit,
        address linkToken
        ) = helperConfig.activeNetworkConfig(); // De constructing 

        // Creating subscription id is not present
        if(subscriptionId==0){
            CreateSubscription getCreatedSubsription =  new CreateSubscription();
            subscriptionId = getCreatedSubsription.createSubscription(vrfCoordinatorAddr);

            // Fund Subscription 
            FundSubsciption fundSubsciption = new FundSubsciption();
            fundSubsciption.fundSubsciption(vrfCoordinatorAddr,subscriptionId,linkToken);
        }

        // Deploying Our Contract
        vm.startBroadcast();
        Raffle raffle = new Raffle(
         fees,
         interval,
         vrfCoordinatorAddr,
         gasLane,
         subscriptionId,
         callBackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumerInteractions(address(raffle), vrfCoordinatorAddr, subscriptionId);
        return (raffle,helperConfig) ;
    }
}
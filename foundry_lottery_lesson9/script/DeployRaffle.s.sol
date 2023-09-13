// SPDX-License-Identifier: MIT

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

pragma solidity ^0.8.18;

contract DeployRaffle is Script{
    function run() external returns(Raffle, HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
       (uint256 fees,
        uint256 interval,
        address vrfCoordinatorAddr,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callBackGasLimit) = helperConfig.activeNetworkConfig(); // De constructing 

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
        return (raffle,helperConfig) ;
    }
}
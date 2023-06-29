// SPDX-License-Identifier: MIT
// Fund Script
// Withdraw Script

pragma solidity ^0.8.18;

import {Script,console} from "forge-std/Script.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundme is Script{
    uint256 SEND_VALUE = 0.1 ether;
    
    function fundFundMe(address mostRecentlyDeployed) public{
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value:SEND_VALUE}();  
        vm.stopBroadcast();     
        console.log("Funded FundMe with %s", SEND_VALUE);
    }

    function run() external{
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        vm.startBroadcast();
        fundFundMe(mostRecentlyDeployed);
        vm.stopBroadcast();
    }

}

contract WithdrawFundme is Script{
    function withDrawFundMe(address mostRecentlyDeployed) public{
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw();   
        vm.stopBroadcast();    
    }

    function run() external{
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid); 
        withDrawFundMe(mostRecentlyDeployed);
    }
}


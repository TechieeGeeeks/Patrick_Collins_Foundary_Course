// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelpConfig.s.sol";

contract DeployFundMe is Script{

    function run() external returns(FundMe){
        //Anything before startbroadcast wont be calculated in gas consumption cause we doing it for mock testing so there is no reason to consider it for test
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();
        vm.startBroadcast();// Real Transaction starts here
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return(fundMe);// Real Transaction ends here
    }
}
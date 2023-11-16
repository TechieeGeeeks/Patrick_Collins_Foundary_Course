// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";


contract DeployDSC is Script{

    address[] private tokenAddresses;
    address[] private priceFeedAddresses;


    function run() external returns(DecentralizedStableCoin, DSCEngine){
        
        HelperConfig config = new HelperConfig();

        (address wEthUsdPriceFeed,
        address wBtcUsdPriceFeed,
        address wEth,
        address wBtc,
        uint256 deployerKey ) = config.activeNetworkConfig();

        tokenAddresses = [wEth,wBtc];
        priceFeedAddresses = [wEthUsdPriceFeed,wBtcUsdPriceFeed];

        vm.startBroadcast(deployerKey);
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        DSCEngine engine = new DSCEngine(tokenAddresses,priceFeedAddresses,address(dsc));

        dsc.transferOwnership(address(engine));
        vm.stopBroadcast();

        return(dsc,engine);
    }

}
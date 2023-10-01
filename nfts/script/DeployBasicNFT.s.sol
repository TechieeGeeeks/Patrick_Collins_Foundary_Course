// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {BasicNft} from "../src/BasicNft.sol";

contract DeployBasicNFT is Script{

    BasicNft basicNft;

    function run() external returns(BasicNft){
        vm.startBroadcast();
        basicNft = new BasicNft();
        vm.stopBroadcast();
        return basicNft;
    }

}
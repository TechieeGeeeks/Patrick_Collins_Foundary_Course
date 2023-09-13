// SPDX-License-Identifier: MIT

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

pragma solidity ^0.8.18;

contract HelperConfig is Script{

    constructor(){
        if(block.chainid == 11155111){
            activeNetworkConfig = getSepoliaEthConfig();
        }else {
            activeNetworkConfig = getOrCreateNetworkConfig();
        }
    }

    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        uint256 fees;
        uint256 interval;
        address vrfCoordinatorAddr;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callBackGasLimit;
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
        return NetworkConfig({
            fees: 0.001 ether,
            interval: 30,
            vrfCoordinatorAddr: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0,// Update this Later
            callBackGasLimit: 500000// 500,000 gas
        });
    }

    function getOrCreateNetworkConfig() public returns(NetworkConfig memory){
        if(activeNetworkConfig.vrfCoordinatorAddr != address(0)){
            return activeNetworkConfig;
        }

        uint96 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9;
        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoodinatorMock = new VRFCoordinatorV2Mock(baseFee, gasPriceLink);
        vm.stopBroadcast();
        
        return NetworkConfig({
            fees: 0.001 ether,
            interval: 30,
            vrfCoordinatorAddr: address(vrfCoodinatorMock),
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0,// Out Script will add this
            callBackGasLimit: 500000// 500,000 gas
        });
    }
}
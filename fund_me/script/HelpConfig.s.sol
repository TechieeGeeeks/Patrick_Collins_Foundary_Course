
//SPDX-License-Identifier: MIT


// Aim1: Deploy contracts when we are on a local anvil chaih
// Aim2: Keep tract of contract address across differnt chains
//    So for example : ETH/USD converter contract deployed on sepplia has a Different Address, on Ethereum it deployed is deployed on Differnt address, on Goerli It would be differnt

// what we want is our config should be able to provide mocks for depending on the chain er are deploying


pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script{

    // so if we are on local anvil we deploy our fake(mock) contract
    // If we want to connect ro live network then we will grab address according to the chain\

// Suppose we want multiple contracts in our implementing contract we can use struct and store multiple contract address for a same network in a single struct of that network

uint8 public constant ETH_DECIMALS = 8;
int256 public constant INITIAL_PRICE = 2000e8;


NetworkConfig public activeNetworkConfig;

    constructor(){
        if(block.chainid==11155111){
            activeNetworkConfig = getSepoliaEthConfig();
        }else if(block.chainid==1){
            activeNetworkConfig= mainnetEthConfig();
        }
        else{
            activeNetworkConfig=getOrCreateAnvilEthConfig();
        }
    }

    struct NetworkConfig{
        address priceFeed;
    }
    

    function getSepoliaEthConfig() public pure returns( NetworkConfig memory){
        // Price Feed Address
        NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed:0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaConfig;
    }

    function mainnetEthConfig() public pure returns( NetworkConfig memory){
        // Price Feed Address
        NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed:0x01D391A48f4F7339aC64CA2c83a07C22F95F587a});
        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory){
        // Price Feed address
        // 1. Deploy The Mocks
        //2. Return the mock address
        if(activeNetworkConfig.priceFeed!=address(0)){
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(ETH_DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();
        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed:address(mockPriceFeed)});
        return anvilConfig;
    }
}
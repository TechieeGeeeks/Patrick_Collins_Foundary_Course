// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {BasicNft} from "../src/BasicNft.sol";

contract mintBasicNft is Script{

    string public nftURI = "https://ipfs.io/ipfs/QmSNRaDmKcPsoXR1sS5hGcHGkVNy1kEEmr3q2YR8CH16Ge?filename=dog.json";

    function run() external{
        address mostRecentlyDeployed = DevOpsTools. get_most_recent_deployment("BasicNft",block.chainid);
        mintNftOnContract(mostRecentlyDeployed);
    }

    function mintNftOnContract(address contractAddress) public{
        vm.startBroadcast();
        BasicNft(contractAddress).mintNft(nftURI);
        vm.stopBroadcast();
    }
}
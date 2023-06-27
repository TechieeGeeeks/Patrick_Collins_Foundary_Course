// SPDX-License-Identifier: MIT
// .s.sol tells that this is deployment contract written in solidity

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

contract DeploySimpleStorage is Script {
    function run() external returns (SimpleStorage) {
        vm.startBroadcast();
        // Everything that you wanna send as a transaction should be in it
        SimpleStorage simpleStorage = new SimpleStorage();
        vm.stopBroadcast();
        return simpleStorage;
    }
}

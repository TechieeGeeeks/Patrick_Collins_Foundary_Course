// contracts/OurToken.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "lib/forge-std/src/Script.sol";
import {StandardToken} from "../src/StandardToken.sol";

contract DeployStandardToken is Script{

    uint256 public constant INITIAL_SUPPLY = 1000 ether;

    function run() external returns(StandardToken){
        vm.startBroadcast();
        StandardToken stt =  new StandardToken(INITIAL_SUPPLY);
        vm.stopBroadcast();
        return stt;
    }

}
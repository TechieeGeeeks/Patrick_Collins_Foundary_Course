// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {BoxV1} from "../src/BoxV1.sol";
import {Script} from "forge-std/Script.sol";
import {BoxV2} from "../src/BoxV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployBox is Script{
    function run() external returns(address){
        address proxy = deployBox();
        return proxy;
    }

    function deployBox() internal returns(address){
        vm.startBroadcast();
        BoxV1 box = new BoxV1();
        ERC1967Proxy proxy = new ERC1967Proxy(address(box),"");
        vm.stopBroadcast();
        return address(proxy);
        
    }
}
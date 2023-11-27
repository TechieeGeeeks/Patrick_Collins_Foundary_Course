// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from  "forge-std/Test.sol";
import {Hack} from "../src/GateKeeper.sol";
import {console} from "forge-std/console.sol";
import "../src/GateKeeper.sol";
import {GateKeeper} from "../src/GateKeeper.sol";

contract GatekeeperTest is Test {
    IGateKeeperOne private target;
    Hack public hack;
    GateKeeper public gtkpr;
    function setUp() public {
        target = IGateKeeperOne(0xb5858B8EDE0030e46C0Ac1aaAedea8Fb71EF423C);
        hack = new Hack();
    }   

    function testRun()external{
        for (uint256 i=100; i<8191; i++){
            try hack.run(address(target),i){
                console.log("gas",i);
                return;
            }catch{} 
        }
        revert("All Failed");
    }

}

// SPDX-License-identitifier: MIT

pragma solidity 0.8.20;

import  {BaseTestv1,HorseStore} from "./Base_TestV1.t.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";

contract HorseStoreHuff is BaseTestv1{
    string public constant HORSE_STORE_HUFF_LOCATION="horseStoreV1/HorseStore";
    function setUp() public override{
        horseStore = HorseStore(HuffDeployer.config().deploy(HORSE_STORE_HUFF_LOCATION));
    }
}
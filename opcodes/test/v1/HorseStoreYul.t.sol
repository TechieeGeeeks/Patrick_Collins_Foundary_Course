// SPDX-License-identitifier: MIT

pragma solidity 0.8.20;

import  {BaseTestv1,IHorseStore} from "./Base_TestV1.t.sol";

import {HorseStoreYul} from "../../src/horseStoreV1/HorseStoreV1.yul.sol";

contract HorseStoreHuff is BaseTestv1{
    function setUp() public override{
        horseStore = IHorseStore(address(new HorseStoreYul()));
    }
}
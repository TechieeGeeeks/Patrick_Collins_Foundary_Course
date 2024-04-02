// SPDX-License-identitifier: MIT

pragma solidity 0.8.20;

import {HorseStore} from "../../src/horseStoreV1/HorseStore.sol";
import {Test, console2} from "forge-std/Test.sol";

abstract contract BaseTestv1 is Test{
    HorseStore public horseStore;

    function setUp() public virtual{
        horseStore = new HorseStore();
    }

    function testReadValue() public {
        uint256 inititalValue = horseStore.readNumberOfHorses();
        assertEq(inititalValue,0);
    }

    function testWriteValue() public{
        uint256 numberOfHorses = 777;
        horseStore.updateHorseNumber(numberOfHorses);
        assertEq(horseStore.readNumberOfHorses(),numberOfHorses);
    }
}
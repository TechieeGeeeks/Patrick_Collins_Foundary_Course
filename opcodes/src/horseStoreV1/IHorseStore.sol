// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

contract IHorseStore {
    function updateHorseNumber(uint256) external {}
    function readNumberOfHorses() external view returns (uint256){}
}
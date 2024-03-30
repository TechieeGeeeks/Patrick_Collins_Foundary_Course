// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract HorseStore {
    uint256 numberOfHorses;

    function updateHorseNumber(uint256 newNumberOfHorses) external {
        numberOfHorses = newNumberOfHorses;
    }

    function readNoOfHorses() external view returns (uint256) {
        return numberOfHorses;
    }
}

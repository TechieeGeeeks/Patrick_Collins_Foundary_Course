// SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test{

    uint256 fees;
    uint256 interval;
    address vrfCoordinatorAddr;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callBackGasLimit;
    

    Raffle raffle;
    HelperConfig helperConfig;
    address public PLAYER= makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
         fees,
         interval,
         vrfCoordinatorAddr,
         gasLane,
         subscriptionId,
         callBackGasLimit
        ) = helperConfig.activeNetworkConfig();
    }

    function testRaffleInitializesToOpenState() public view{
        assert(raffle.getRaffleState()== Raffle.RaffleState.OPEN);
    }
}
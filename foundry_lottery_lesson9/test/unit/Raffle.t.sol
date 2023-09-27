// SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";

contract RaffleTest is Test{
    /** Events */
    event EnteredRaffle(address indexed player);

    uint256 fees;
    uint256 interval;
    address vrfCoordinatorAddr;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callBackGasLimit;
    address linkToken;

    Raffle raffle;
    HelperConfig helperConfig;
    address public PLAYER= makeAddr("player");
    address public PLAYER1= makeAddr("Player1");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    /* 0. Setting up for testing contract */
    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
         fees,
         interval,
         vrfCoordinatorAddr,
         gasLane,
         subscriptionId,
         callBackGasLimit,
         linkToken
        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
        vm.deal(PLAYER1, STARTING_USER_BALANCE);
    }

    /* 1. Enter Raffle function tests */
    function testRaffleInitializesToOpenState() public view{
        assert(raffle.getRaffleState()== Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);
        // Act + Assert
        vm.expectRevert(Raffle.Raffle__notEnoughEth_ERROR.selector);
        raffle.enterRaffle();
    } 

    function testRaffleRecordPlayerWhenTheyEnter() public{
        vm.prank(PLAYER);
        raffle.enterRaffle{value: fees}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventsOnEnter() public{
        // Read Expect Emit docs + Patrick bhai course
        vm.prank(PLAYER);
        vm.expectEmit(true,false,false, false, address(raffle)); // How many topics are there in event
        // for 1 topic true, false, false
        // Last 4th false is there for to know if there is any non-indexed parameters or not

        //Emit Event here 
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value:fees}();
    }

    function testCantEnterWhenRaffleIsCalculatingWinner() public{
        //  To do this we want three true statments to be true checkout checkUpkeep
        vm.prank(PLAYER);
        raffle.enterRaffle{value: fees}(); // 1st 2nd true 
        vm.warp(block.timestamp+ interval +1); // 3rd true
        vm.roll(block.number+1); 
        raffle.performUpkeep("");

        // Now trying to eneter in lottery via another account
        vm.prank(PLAYER1);
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: fees}();
    }

    /* 2. CheckUp keep Function tests */
    function testCheckUpKeepReturnsFalseIfItHasNoBalance() public{
     // The Check Up Keep function should return false when the raffle does not enough balance

        //Arrange
        vm.warp(block.timestamp+ interval +1); //Sets the timstamp
        vm.roll(block.number+1); // Sets the Block Number

        //Act
        (bool upKeepNeeded,)=raffle.checkUpkeep("");
        
        //Assert
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfRaffleNotOpen() public{
    // The Check Up Keep function should return false when the raffle is not open

        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: fees}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);
        raffle.performUpkeep("");

        //Act
        (bool checkUpkeepNeeded,) = raffle.checkUpkeep("");

        //Assert
        assert(!checkUpkeepNeeded);
    }
    
    function testCheckUpKeepReturnsFalseIfEnoughTimeHasntPassed() public{

        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value:fees}();
        vm.warp(block.timestamp);

        // Act 
        (bool checkUpkeepNeeded,) = raffle.checkUpkeep("");

        // Assert 
        assert(!checkUpkeepNeeded);
    }

    function testCheckUpKeepReturnsTrueWhenParametersAreGood() public{
        
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value:fees}();
        vm.warp(block.timestamp+interval+1);
        // As player can only enter by paying fees and after he enters the players lenght will be more than one 
        // All three parameters are satisfied

        // Act 
        (bool checkUpkeepNeeded,) = raffle.checkUpkeep("");

        // Assert 
        assert(checkUpkeepNeeded);

    }

    /* 3. performUp keep Function tests */

    function testPerformUpKeepCanOnlyRunIfCheckUpKeepIsTrue() public{
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value:fees}();
        vm.warp(block.timestamp+interval+1);

        // Act-Assert
        raffle.performUpkeep("");
    }

    function testPerformUpKeepRevertsIfCheckUpKeepIsFalse() public{
        
        //Arrange
        vm.prank(PLAYER);
        uint256 currentBalance =0;
        uint256 numPlayer =0;
        uint256 raffleState =0 ;

        //Act
        //Assert (Refer Foundry doc of expectRevert with custom errors)
        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__UpkeepNeeded.selector,currentBalance,numPlayer,raffleState));
        raffle.performUpkeep("");
    }

    function testPerformUpKeepUpdatesReffleStateAndEmitsRequestId() public{
         // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value:fees}();
        vm.warp(block.timestamp+interval+1);

        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        Raffle.RaffleState rState = raffle.getRaffleState();

        //assert
        bytes32 requestId = entries[1].topics[1];
        assert(uint256(requestId)>0);
        assert(uint256(rState) ==1);
    }

}
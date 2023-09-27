// SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "../mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
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
    address public PLAYER = makeAddr("player");
    address public PLAYER1 = makeAddr("Player1");
    uint256 public constant STARTING_USER_BALANCE = 1 ether;

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
    function testRaffleInitializesToOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);
        // Act + Assert
        vm.expectRevert(Raffle.Raffle__notEnoughEth_ERROR.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: fees}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventsOnEnter() public {
        // Read Expect Emit docs + Patrick bhai course
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle)); // How many topics are there in event
        // for 1 topic true, false, false
        // Last 4th false is there for to know if there is any non-indexed parameters or not

        //Emit Event here
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: fees}();
    }

    function testCantEnterWhenRaffleIsCalculatingWinner() public {
        //  To do this we want three true statments to be true checkout checkUpkeep
        vm.prank(PLAYER);
        raffle.enterRaffle{value: fees}(); // 1st 2nd true
        vm.warp(block.timestamp + interval + 1); // 3rd true
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        // Now trying to eneter in lottery via another account
        vm.prank(PLAYER1);
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: fees}();
    }

    /* 2. CheckUp keep Function tests */
    function testCheckUpKeepReturnsFalseIfItHasNoBalance() public {
        // The Check Up Keep function should return false when the raffle does not enough balance

        //Arrange
        vm.warp(block.timestamp + interval + 1); //Sets the timstamp
        vm.roll(block.number + 1); // Sets the Block Number

        //Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");

        //Assert
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfRaffleNotOpen() public {
        // The Check Up Keep function should return false when the raffle is not open

        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: fees}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        //Act
        (bool checkUpkeepNeeded, ) = raffle.checkUpkeep("");

        //Assert
        assert(!checkUpkeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfEnoughTimeHasntPassed() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: fees}();
        vm.warp(block.timestamp);

        // Act
        (bool checkUpkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(!checkUpkeepNeeded);
    }

    function testCheckUpKeepReturnsTrueWhenParametersAreGood() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: fees}();
        vm.warp(block.timestamp + interval + 1);
        // As player can only enter by paying fees and after he enters the players lenght will be more than one
        // All three parameters are satisfied

        // Act
        (bool checkUpkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(checkUpkeepNeeded);
    }

    /* 3. performUp keep Function tests */

    function testPerformUpKeepCanOnlyRunIfCheckUpKeepIsTrue() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: fees}();
        vm.warp(block.timestamp + interval + 1);

        // Act-Assert
        raffle.performUpkeep("");
    }

    function testPerformUpKeepRevertsIfCheckUpKeepIsFalse() public {
        //Arrange
        vm.prank(PLAYER);
        uint256 currentBalance = 0;
        uint256 numPlayer = 0;
        uint256 raffleState = 0;

        //Act
        //Assert (Refer Foundry doc of expectRevert with custom errors)
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNeeded.selector,
                currentBalance,
                numPlayer,
                raffleState
            )
        );
        raffle.performUpkeep("");
    }

    modifier RaffleEnterAndTimePassed() {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: fees}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpKeepUpdatesReffleStateAndEmitsRequestId() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: fees}();
        vm.warp(block.timestamp + interval + 1);

        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        Raffle.RaffleState rState = raffle.getRaffleState();

        //assert
        bytes32 requestId = entries[1].topics[1];
        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1);
    }

    /* FUZZ Test
        The testing function is receiving a number which will be generated bt foundry
        This number is random to test edge cases randomly to make sure that our 
        contracts behaves correctly on all edge cases*/

    function testFullfillRandomWordsCanOnlyBeCalledAfterPerformUpKeep(
        uint256 randomRequestId
    ) public RaffleEnterAndTimePassed {
        // Arrange
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinatorAddr).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFullfillRandomWordsPicksWinnerResetsAndSendsMoney()
        public
        RaffleEnterAndTimePassed
    {
        // Arrange
        // We are making 5 players enter over here
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;
        for (
            uint i = startingIndex;
            i < startingIndex + additionalEntrants;
            i++
        ) {
            address player = address(uint160(i));
            hoax(player, 1 ether); // deal 1 eth to the player
            raffle.enterRaffle{value: fees}();
        }

        uint256 prize = fees * (additionalEntrants + startingIndex);

        // Pretending to be VRFCoordinator contract
        /* We have to test
            1. Listens to the Consumer contract events
            2. Chcks if the request is legit
            3. Returns random Number by calling fullfillRandomWords from consumer contract
            4. In consumer contract pick the winner 
            5. Give him money
            6. Reset all the raffle contract settings after winner has been picked
         */

        //1. Catching to the events emitted by raffle contract (Consumer)
        // Cause chainlink listens to the same event for giving random words
        vm.recordLogs();
        raffle.performUpkeep(""); // Will emit request id
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        uint256 previousTimeStamp = raffle.getLastTimeStamp();

        // 2. Pretend to be chainlink vrf and respond to the emitted event and give back random word to consumer contract via calling fullfillRandomWords
        VRFCoordinatorV2Mock(vrfCoordinatorAddr).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        bytes32 bytes32Value = entries[2].topics[1];
        address addressValue = address(uint160(uint256(bytes32Value)));
        // console.log("addressValue:", addressValue);
        // console.log(raffle.getRecentWinner(),"Expected Winner");
        //Assert
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getPlayersLength() == 0);
        assert(previousTimeStamp < raffle.getLastTimeStamp());
        // assert(raffle.getRecentWinner()==recentEmittedWinner);
        assert(
            raffle.getRecentWinner().balance ==
                STARTING_USER_BALANCE + prize - fees
        );
    }
}
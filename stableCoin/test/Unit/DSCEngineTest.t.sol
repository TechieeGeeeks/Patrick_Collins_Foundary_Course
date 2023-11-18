// SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;
    address wEthUsdPriceFeed;
    address wEth;
    address wBtcUsdPriceFeed;
    address wBtc;
    address public user = makeAddr("Swayam");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    modifier depositCollateral(){
        vm.startPrank(user);
        ERC20Mock(wEth).approve(address(dsce),AMOUNT_COLLATERAL);
        dsce.depositCollateral(wEth,AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (wEthUsdPriceFeed, wBtcUsdPriceFeed, wEth, wBtc,) = config.activeNetworkConfig();
        ERC20Mock(wEth).mint(user, STARTING_ERC20_BALANCE);
        ERC20Mock(wBtc).mint(user, STARTING_ERC20_BALANCE);
    }

    /**
     * Constructor tests
     */

    function testRevertsConstructorIfTokenLenghtDoesNotMatchPriceFeeds() public {
        tokenAddresses.push(wEth);
        priceFeedAddresses.push(wEthUsdPriceFeed);
        priceFeedAddresses.push(wBtcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine_TokenAddressesAndPriceFeedAddressesMustBeOfSameLength.selector);
        new DSCEngine(tokenAddresses,priceFeedAddresses,address(dsc));
    }

    /**
     * Price Feed tests
     */
    function testGetUsdValueOfToken() public {
        uint256 ethAmount = 15e18;
        uint256 expectedUsdForEthValue = 30000e18;
        uint256 actualUsdValue = dsce.getUsdValueOfToken(wEth, ethAmount);
        assertEq(expectedUsdForEthValue, actualUsdValue);
    }

    function testGetTokenAmountFromUsd() public{
        uint256 usdAmount = 100 ether;
        uint256 expectedWEth = 0.05 ether;
        uint256 actualWeth = dsce.getTokenAmountFromUsd(wEth, usdAmount);
        assertEq(actualWeth,expectedWEth);
    }

    /**
     * Deposit Collateral Test
     */
    function testRevertIfCollateralIsZero() public {
        vm.startPrank(user);
        ERC20Mock(wEth).approve(address(dsce), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine_NeedsMoreThanZero.selector);
        dsce.depositCollateral(address(wEth), 0);
    }

    function testRevertIfCollateralTokenIsNotAllowed() public{
        vm.startPrank(user);
        vm.expectRevert(DSCEngine.DSCEngine_NotAllowedToken.selector);
        dsce.depositCollateral(address(0),1000);
        vm.stopPrank();
    }

    function testIfTheTokenCollateralHasBeenSavedOrNot() public{
        vm.startPrank(user);
        ERC20Mock(wEth).approve(address(dsce),AMOUNT_COLLATERAL);
        dsce.depositCollateral(wEth,AMOUNT_COLLATERAL);
        uint256 expectedCollateralAmount = AMOUNT_COLLATERAL;
        uint256 actualCollateralAmount = dsce.getTotalCollateralDeposited(user,address(wEth));
        assertEq(actualCollateralAmount,expectedCollateralAmount);
        vm.stopPrank();
    }

     function testGetAccountCollateralValue() public {
        vm.startPrank(user);
        ERC20Mock(wEth).approve(address(dsce),AMOUNT_COLLATERAL);
        ERC20Mock(wBtc).approve(address(dsce),AMOUNT_COLLATERAL);
        dsce.depositCollateral(wEth,AMOUNT_COLLATERAL);
        dsce.depositCollateral(wBtc,AMOUNT_COLLATERAL);
        uint256 expectedValue = (AMOUNT_COLLATERAL*2000)+(AMOUNT_COLLATERAL*1000);
        uint256 actualValue = dsce.getAccountCollateralValue(user);
        assertEq(expectedValue,actualValue);
        vm.stopPrank();
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositCollateral{
        (uint256 totalDscMinted, uint256 collateralValue) = dsce.getAccountInformation(user);
        uint256 expectedDscMinted = 0;
        uint256 actualCollateralValueInUsd = dsce.getTokenAmountFromUsd(wEth,collateralValue);
        assertEq(totalDscMinted,expectedDscMinted);
        assertEq(actualCollateralValueInUsd,AMOUNT_COLLATERAL);
    }
    
}

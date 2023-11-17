// SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;
    address wEthUsdPriceFeed;
    address wEth;
    address wBtcUsdPriceFeed;
    address wBtc;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (wEthUsdPriceFeed, wBtcUsdPriceFeed, wEth, wBtc,) = config.activeNetworkConfig();
    }

    /**
     * Price Feed tests function
     */

    function testGetUsdValueOfToken() public {
        uint256 ethAmount = 15e18;
        uint256 expectedUsdForEthValue = 30000e18;
        uint256 actualUsdValue = dsce.getUsdValueOfToken(wEth,ethAmount);
        assertEq(expectedUsdForEthValue,actualUsdValue);
    }
}

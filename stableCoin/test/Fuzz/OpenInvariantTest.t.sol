/**
 * @title Invariant Testing for Contracts
 * @author DevSwayam
 * @notice This File we will have Invariants that we wanna break
 *
 * @Invariants:
 *      - The total supply of DSC should always be less than total collateral value
 *      - Getter view functions should never revert <- Ever Green Invariant
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OpenInvariantTest is StdInvariant, Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsCoin;
    DSCEngine engine;
    HelperConfig config;
    address wEth;
    address wBtc;

    function setUp() external {
        deployer = new DeployDSC();
        (dsCoin, engine, config) = deployer.run();
        (,, wEth, wBtc,) = config.activeNetworkConfig();
        targetContract(address(engine));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view{
        uint256 totalSupply = dsCoin.totalSupply();
        uint256 totalWethDeposited = IERC20(wEth).balanceOf(address(engine));
        uint256 totalWbtcDeposited = IERC20(wBtc).balanceOf(address(engine));
        
        uint256 wEthValue = engine.getUsdValueOfToken(wEth,totalWethDeposited);
        uint256 wBtcValue = engine.getUsdValueOfToken(wBtc,totalWbtcDeposited);

        console.log("Weth value is = ",wEthValue);
        console.log("Wbtc value is = ",wBtcValue);
        console.log( "Total Supply is = ",totalSupply);

        assert(wEthValue+wBtcValue >= totalSupply);
    }
}

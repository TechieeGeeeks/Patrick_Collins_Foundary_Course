/**
 * @notice This File we will have Handlers that help us testing (Like how we use modifiers while testing) so that we wont waste runs
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";


contract Handler is Test {
    DecentralizedStableCoin dsCoin;
    DSCEngine engine;
    ERC20Mock wEth;
    ERC20Mock wBtc;

    uint256 MAX_DEPOSIT_COLLATERAL_SIZE = type(uint96).max;
    address[] public usersWithCollateralDeposited;
    uint256 public timesMinted;

    constructor(DSCEngine _engine, DecentralizedStableCoin _dsCoin) {
        dsCoin = _dsCoin;
        engine = _engine;

        address[] memory collateralTokens = engine.getCollateralTokens();
        wEth = ERC20Mock(collateralTokens[0]);
        wBtc = ERC20Mock(collateralTokens[1]);
    }

    // redeem Collateral <- Call this only when you have collateral
    function depositCollateral(uint256 collateralContractSeed, uint256 amountCollateral) public {
        // This lets you attack with only valid collateral addresses(means wEth ot wBtc)
        ERC20Mock collateralContract = _getCollateralFromSeed(collateralContractSeed);
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_COLLATERAL_SIZE);

        vm.startPrank(msg.sender);
        collateralContract.mint(msg.sender, amountCollateral);
        collateralContract.approve(address(engine), amountCollateral);
        engine.depositCollateral(address(collateralContract), amountCollateral);
        vm.stopPrank();

        usersWithCollateralDeposited.push(msg.sender);
    }

    function mintDsc(uint256 amount, uint256 addressSeed) public {
        if (usersWithCollateralDeposited.length == 0 || addressSeed > usersWithCollateralDeposited.length) {
            return;
        }
        address sender = usersWithCollateralDeposited[addressSeed % usersWithCollateralDeposited.length];
        (uint256 totalDscMinted, uint256 collateralValue) = engine.getAccountInformation(sender);
        if (int256(collateralValue / 2) < int256(totalDscMinted)) {
            return;
        }
        int256 dscToMint = (int256(collateralValue / 2) - int256(totalDscMinted));
        if (dscToMint < 0) {
            return;
        }
        amount = bound(amount, 0, uint256(dscToMint));
        if (amount == 0) {
            return;
        }
        vm.startPrank(sender);
        timesMinted++;
        engine.mintDSC(amount);
        vm.stopPrank();
    }

    function redeemCollateral(uint256 collateralContractSeed, uint256 amountCollateral) public {
        ERC20Mock collateralContract = _getCollateralFromSeed(collateralContractSeed);
        uint256 amountOfCollateralCanBeRedeem =
            engine.getCollateralBalanceOfUser(msg.sender, address(collateralContract));
        amountCollateral = bound(amountCollateral, 0, amountOfCollateralCanBeRedeem);
        if (amountCollateral == 0) {
            return;
        }
        engine.redeemCollateral(address(collateralContract), amountCollateral);
    }

    // Helper Functions
    function _getCollateralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return wEth;
        }
        return wBtc;
    }
}

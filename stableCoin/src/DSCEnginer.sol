 // SPDX-License-Identifier: MIT


// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions


pragma solidity ^0.8.18;


import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/** 
 * @title DecentralizedStableCoin
 * @author DevSwayam
 * This is the contract is desgined to maintain each token value to be equal to 1$ peg
 * This Stablecoin has properties
 * - Exogenous Collateral
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is simillar to DAI is DAI had no governance, no fees, and was only backed by wETH and wBTC.
 *
 * Our DSC system should always be over Collateralised at no point, should the value of all collateral <= the $back value of all DSC.
 *
 * @notice This contract is the core logic of the DSC System. It handles all the logic for minting and redeeming DSC, as well as depositing and Withdrawing Collateral.
 * @notice this contract is very loosely based on MakerDAO DSS (DAI) System.
 */


contract DSCEngine is ReentrancyGuard{


    /** Errors */
    error DSCEngine_NeedsMoreThanZero();
    error DSCEngine_TokenAddressesAndPriceFeedAddressesMustBeOfSameLength();
    error DSCEngine_NotAllowedToken();


    /** State Variables */
    DecentralizedStableCoin private i_dsc; 
    mapping(address token => address priceFeeds) private s_priceFeeds;


     /** Modifiers */
    modifier moreThanZero(uint256 amount){
        if(amount<=0){
            revert DSCEngine_NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address tokenAddress){
       if(s_priceFeeds[tokenAddress] == address(0)){
        revert DSCEngine_NotAllowedToken();
       }
        _;
    }


    /** Constructor */
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress){
        // It will be USD Price Feeds
        if(tokenAddresses.length!=priceFeedAddresses.length){
            revert DSCEngine_TokenAddressesAndPriceFeedAddressesMustBeOfSameLength();
        }

        for(uint i = 0; i<tokenAddresses.length; i++){
            s_priceFeeds[tokenAddresses[i]]=priceFeedAddresses[i];
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }



    /**External Functions */
    function depositCollateral(address tokeCollateralAddress, uint256 amountCollateral ) external moreThanZero(amountCollateral)isAllowedToken(tokeCollateralAddress) nonReentrant{
        /**
         * @param tokenCollateralAddress address is the address of the token which will be deposited as collateral  
         * @param amountCollateral is the amount of collateral tokens to deposit
        */
    }

    function depositCollateralAndMintDSC() external{}

    function redeemCollateralForDSC()external{}

    function redeemCollateral() external{}
    
    function mintDSC() external{}

    function burnDSC() external{}

    function liquidate() external{}

    function getHealthFactor() external{}


}
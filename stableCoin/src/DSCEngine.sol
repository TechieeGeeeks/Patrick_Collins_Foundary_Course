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
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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

contract DSCEngine is ReentrancyGuard {
    /**
     * Errors
     */
    error DSCEngine_NeedsMoreThanZero();
    error DSCEngine_TokenAddressesAndPriceFeedAddressesMustBeOfSameLength();
    error DSCEngine_NotAllowedToken();
    error DSCEngine_TokenTransferFailed();
    error DSCEngine_BreakHealthFactor(uint256 userHealthFactor);
    error DSCEngine_TokenMintFailed();

    /**
     * State Variables
     */

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 100;

    DecentralizedStableCoin private i_dsc;
    mapping(address token => address priceFeeds) private s_priceFeeds;
    mapping(address users => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountToBeMinted) private s_DSCMinted;

    address[] private s_collateralTokens;

    /**
     * Events
     */
    event collateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    /**
     * Modifiers
     */
    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert DSCEngine_NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address tokenAddress) {
        if (s_priceFeeds[tokenAddress] == address(0)) {
            revert DSCEngine_NotAllowedToken();
        }
        _;
    }

    /**
     * Constructor
     */
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        // It will be USD Price Feeds
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine_TokenAddressesAndPriceFeedAddressesMustBeOfSameLength();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(priceFeedAddresses[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    /**
     * Public Functions
     */
    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        // loop through each collateral token and get the amount they have deposited to and map it to the price to get the USD value
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValueOfToken(token, amount);
        }
        return totalCollateralValueInUsd;
    }

    function getUsdValueOfToken(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return (uint256(uint256(price) * ADDITIONAL_FEED_PRECISION) * amount)/PRECISION;
    }

    /**
     * External Functions
     */
    function depositCollateral(address tokeCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokeCollateralAddress)
        nonReentrant
    {
        /**
         * @notice Follows CEI pattern
         * @param tokenCollateralAddress address is the address of the token which will be deposited as collateral
         * @param amountCollateral is the amount of collateral tokens to deposit
         */

        s_collateralDeposited[msg.sender][tokeCollateralAddress] += amountCollateral;
        emit collateralDeposited(msg.sender, tokeCollateralAddress, amountCollateral);
        bool sucess = IERC20(tokeCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);

        if (!sucess) {
            revert DSCEngine_TokenTransferFailed();
        }
    }

    function depositCollateralAndMintDSC() external {}

    function redeemCollateralForDSC() external {}

    function redeemCollateral() external {}

    function mintDSC(uint256 amountDSCToMint) external moreThanZero(amountDSCToMint) nonReentrant {
        /**
         * @notice Follows CEI
         * @param Amount of DSC tokens to be minted
         * @notice They must have minimum collateral value than the minimum threshold
         */

        s_DSCMinted[msg.sender] = amountDSCToMint;
        _revertIfHealthFactorIsBroken(msg.sender);

        bool minted = i_dsc.mint(msg.sender,amountDSCToMint);
        if(!minted){
            revert DSCEngine_TokenMintFailed();
        }
    }

    function burnDSC() external {}

    function liquidate() external {}

    function getHealthFactor() external {}

    /**
     * internal or private view Functions
     */

    function _healthFactor(address user) private view returns (uint256) {
        /**
         * @notice CEI
         * @param user address to know which users health factor is being calculated
         * @notice If the health factor is below 1 they can get liquidated
         */

        // total DSC minted
        // total Collateral Value

        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd*LIQUIDATION_THRESHOLD)/LIQUIDATION_PRECISION;
        return(collateralAdjustedForThreshold/ PRECISION)/totalDscMinted;
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        // 1. Check Health Factor (Do they have Enough Collateral)
        // 2. Revert if they dont ghave a good health factor
        uint256 userHealthFactor = _healthFactor(user);
        if(userHealthFactor<MIN_HEALTH_FACTOR){
            revert DSCEngine_BreakHealthFactor(userHealthFactor);
        }
    }

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }
}

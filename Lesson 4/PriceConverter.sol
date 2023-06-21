// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{

    // This Means that all uint256 ha access to PriceConverter library functions
    using PriceConverter for uint256;

    function getPrice() internal view returns(uint256){
        // Address = 0x694AA1769357215DE4FAC081bf1f309aDC325306
        // ABI 

        //Instantiated contract
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (,int256 answer,,,)= priceFeed.latestRoundData();
        // Price of ETH in interms of USD Return value like 2000,0000,0000
        // So The Effective value is 2000.00000000 we have to get rid of the last 8 zeros
        // In solidity msg.value returns in wei format so it would be 10to power 18 and we have 10 to power9
        // So basically we have to multiply it to 10 to power 10 to get 10 to power 18 as we already have to 10 to power 8
        // Simple 10^8 + 10^10 = 10^18
        return uint256(answer*1e10);// Typecasting int to uint
    }
    function getConversionRate(uint256 ethAmount) internal view returns(uint256){
        uint256 currentEthInUsd = getPrice();
        // Dont worry both are in 10^18 format so 10^18 x 10^18 = 10^36 
        // So hence we are dividing it by 10^18
        uint256 ethAmountInUsd = (currentEthInUsd* ethAmount)/1e18;
        return ethAmountInUsd;
    }

    function getVersion() internal view returns(uint256){
        return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
    }

}
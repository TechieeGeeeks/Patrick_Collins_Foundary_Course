// contracts/StandardToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzepplin/token/ERC20/ERC20.sol";

contract StandardToken is ERC20{
    constructor(uint256 _inititalSupply) ERC20("StandardToken", "STT"){
        _mint(msg.sender,_inititalSupply);
    }
}

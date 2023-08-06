// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {SimpleStorage} from "./SimpleStorage.sol";
contract StorageFactory{
    
    SimpleStorage[] public listOfSimpleStorageContracts;

    function createSimpleStorageContract() public{
      SimpleStorage simpleStorage = new SimpleStorage();
      listOfSimpleStorageContracts.push(simpleStorage);
    }

    function sfStore(uint _simpleStorageIndex, uint256 _newSimpleStorageFavouriteNumber) public{
         listOfSimpleStorageContracts[_simpleStorageIndex].store(_newSimpleStorageFavouriteNumber); 
        
    }

    function sfGet(uint256 _simpleStorageIndex) public view returns(uint256){
        return  listOfSimpleStorageContracts[_simpleStorageIndex].retrieve();
    }
}
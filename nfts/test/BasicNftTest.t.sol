// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployBasicNFT} from "../script/DeployBasicNFT.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {BasicNft} from "../src/BasicNft.sol";

contract BasicNftTest is Test{
    BasicNft public basicNft;
    DeployBasicNFT public deployer;
    address public swayam = makeAddr('swayam');
    string public nftURI = "https://ipfs.io/ipfs/QmSNRaDmKcPsoXR1sS5hGcHGkVNy1kEEmr3q2YR8CH16Ge?filename=dog.json";

    function setUp() public{
        deployer = new DeployBasicNFT();
        basicNft = deployer.run();
    }

    function testNameOfNftIsCorrect() public view {
        string memory expectedName = "CuteDog";
        string memory actualName = basicNft.name();
        assert(keccak256(abi.encodePacked(expectedName))==keccak256(abi.encodePacked(actualName)));
    }

    function testIfTokenCanBeMint() public{
        vm.prank(swayam);
        basicNft.mintNft(nftURI);
        assert(basicNft.balanceOf(swayam) == 1);
        string memory actualTokenURI = basicNft.tokenURI(0);
        assert(keccak256(abi.encodePacked(nftURI))==keccak256(abi.encodePacked(actualTokenURI)));
    }

}
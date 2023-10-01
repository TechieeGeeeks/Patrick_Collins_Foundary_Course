// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployMoodNft} from "../../script/DeployMoodNft.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {MoodNft} from "../../src/MoodNft.sol";

contract DeployMoodNftTest is Test {
    DeployMoodNft public deployMoodNFT;

    address public swayam = makeAddr("swayam");
    string public constant EXPECTED_SVG_OUTPUT =
        "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB3aWR0aD0iNTAwIiBoZWlnaHQ9IjUwMCI+PHRleHQgeD0iMCIgeT0iMTUiIGZpbGw9ImJsYWNrIj5IaSEgWW91ciBicm93c2VyIGRlY29kZWQgdGhpczwvdGV4dD48L3N2Zz4=";

    string public constant SVG_IMAGE='<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="500" height="500"><text x="0" y="15" fill="black">Hi! Your browser decoded this</text></svg>';

    function setUp() public {
        deployMoodNFT = new DeployMoodNft();
    }

    function testIfDeployScriptGivesSameSvgUri() view public {
        string memory output = deployMoodNFT.svgToImageUri(SVG_IMAGE);
        assert(keccak256(abi.encodePacked(EXPECTED_SVG_OUTPUT))==keccak256(abi.encodePacked(output)));
    }

    /*
    function testIfReturnedURIIsSameAsExpected() public{
        vm.prank(swayam);
        moodNft.minNft();
        assertEq(keccak256(abi.encodePacked(HAPPY_MOOD_URI)),keccak256(abi.encodePacked(moodNft.tokenURI(0))));
    }*/
}

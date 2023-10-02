// SPDX-License-Identifier: Mit

pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MoodNft is ERC721 {
    uint256 private s_token_counter;
    string private s_sadSvgImageURI;
    string private s_happSvgImageURI;
    enum Mood {
        Happy,
        Sad
    }
    mapping(uint256 => Mood) private s_tokenIdToMood;

    error MoodNft_CanrFlipMoodIfNotOwner();

    constructor(
        string memory sadSvgImageUri,
        string memory happSvgImageUri
    ) ERC721("Mood NFT", "MNT") {
        s_token_counter = 0;
        s_sadSvgImageURI = sadSvgImageUri;
        s_happSvgImageURI = happSvgImageUri;
    }

    function minNft() public {
        _safeMint(msg.sender, s_token_counter);
        s_tokenIdToMood[s_token_counter] = Mood.Happy;
        s_token_counter++;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function flipMood(uint256 tokenId) public{
        if(!_isApprovedOrOwner(msg.sender, tokenId)){
            revert MoodNft_CanrFlipMoodIfNotOwner();
        }
        if(s_tokenIdToMood[tokenId]==Mood.Happy){
            s_tokenIdToMood[tokenId]=Mood.Sad;
        }else{
            s_tokenIdToMood[tokenId]=Mood.Happy;
        }
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory imageURI;

        if (s_tokenIdToMood[tokenId] == Mood.Happy) {
            imageURI = s_happSvgImageURI;
        } else {
            imageURI = s_sadSvgImageURI;
        }

        return string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name(), // You can add whatever name here
                            '", "description":"An NFT that reflects the mood of the owner, 100% on Chain!", ',
                            '"attributes": [{"trait_type": "moodiness", "value": 100}], "image":"',
                            imageURI,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function getMoodOfNft(uint256 tokenId) external view returns(Mood){
        return s_tokenIdToMood[tokenId];
    }
}

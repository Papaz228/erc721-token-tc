// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AlanToken is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;


    Counters.Counter private _tokenIdCounter;

    uint256 public maxSupply;
    string baseTokenURI;
    mapping (uint256 => uint256) tokensWithPrice;


    modifier tokenExist(uint256 tokenId) {
        require(_exists(tokenId), "Token doesn't exist");
        _;
    }

    modifier tokenIsListed(uint256 tokenId){
        require(tokensWithPrice[tokenId] != 0, "Token hasn't been listed yet");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "You are not owner of this token");
        _;
    }

    constructor() ERC721("AlanToken", "ALA") {
        maxSupply = 5;
        baseTokenURI = "ipfs://QmYAiRCT8kW9si9FRzrkiGo5S5rDV5uzuw41er6vQgraDT/";
    }

    function changeMaxSupply(uint256 newSupply) public onlyOwner {
        maxSupply = newSupply;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function changeBaseURI(string calldata newBaseUri) public onlyOwner {
        baseTokenURI = newBaseUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override tokenExist(tokenId) returns (string memory){
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function createItem(address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, "Max limit!!!");
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function listItem(uint256 tokenId, uint256 price) public tokenExist(tokenId) onlyTokenOwner(tokenId) {
        require(price > 0, "Price must be greater than 0");
        tokensWithPrice[tokenId] = price;
    }

    function cancel(uint256 tokenId) public tokenExist(tokenId) onlyTokenOwner(tokenId) tokenIsListed(tokenId) {
        tokensWithPrice[tokenId] = 0;
    }

    function buyItem(uint256 tokenId) public payable tokenExist(tokenId) tokenIsListed(tokenId) returns (bool) {
        require(msg.value >= tokensWithPrice[tokenId], "Not enough money to buy this Token");
        require(ownerOf(tokenId) != msg.sender, "You can't buy your own token");
        address from = ownerOf(tokenId);
        address to = msg.sender;
        _approve(msg.sender, tokenId);
        _safeTransfer(from, to, tokenId, "Token was transfered");
        tokensWithPrice[tokenId] = 0;
        return true;
    }

}

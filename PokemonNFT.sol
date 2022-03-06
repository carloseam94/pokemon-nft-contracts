//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";

// Import the OpenZeppeling Contracts
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// import merkletree contract
import "./MerkleTree.sol";

// Inherit the OpenZeppeling contract to create robust contracts
contract PokemonNFT is ERC721URIStorage {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Black svg with white text over it
    string svg1 = '<svg width="400" height="400" viewBox="0 0 400 400" xmlns="http://www.w3.org/2000/svg"><rect width="100%" height="100%"/><text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" style="fill:#fff;font-family:sans;font-size:30px">';
    string svg2 = "</text></svg>";

    // We are gonna pick one of these randomly to generate the NFT
    string[] pokemons = [
        "Jolteon",
        "Sceptile",
        "Dragonite",
        "Kingdra",
        "Sneasler",
        "Drapion",
        "Sprigatito"
    ];

     MerkleTree public merkleTree;
     uint256 public limit_to_mint;

    // Notify the frontend whenever a new NFT is succesfully minted
    event NewNFTMinted(address sender, uint256 tokenId);

    // Constructor following ERC721 protocol (name and symbol)
    constructor(uint256 _limit_to_mint) ERC721("PokemonNFT", "POKE") {
        console.log("Pokemon NFT contract");
        limit_to_mint = _limit_to_mint;
        // initialize the merkle tree that we are going to send minted data
        merkleTree = new MerkleTree(limit_to_mint);
    }

    // Generate a random number (well, kinda, pseudo-pseudo-random but still :) 
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    // Make use of the above random function to pick a pokemon
    function pickRandomPokemon(uint256 tokenId) public view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked("POKE", Strings.toString(tokenId))));
        return pokemons[rand % pokemons.length];
    }

    // to provide the front end with the leaves of the merkle tree, we'll use this to generate and verify a snk proof
    function getMerkleTreeLeaves() public view returns (bytes32[] memory) {
        return merkleTree.getLeaves();
    }

    // to allow to mint a maximun number of nfts int the front
    function getCurrentIndex() public view returns (uint256) {
        return _tokenIds.current();
    }

    function getLimit() public view returns (uint256) {
        return limit_to_mint;
    }

    // Function to build and mint the NFT
    function makeAPokemonNFT(address personAddress) public {
        require(_tokenIds.current() < limit_to_mint, "Surpassed the limit, cant mint anymore");
        
        uint256 newItemId = _tokenIds.current();

        string memory svg3 = string(abi.encodePacked(svg1, pickRandomPokemon(newItemId), svg2));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "', pickRandomPokemon(newItemId),
                        '", "description": "A collection of cool pokemon names.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg3)),
                        '"}'
                    )
                )
            )
        );

        string memory tokenUri = string(abi.encodePacked("data:application/json;base64,", json));
        
        // Mint and update the URI
        _safeMint(personAddress, newItemId);
        _setTokenURI(newItemId, tokenUri);
        
        // create data to insert in the merkle tree
         string memory pokemonNFTInfo = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"sender": "', msg.sender,
                        '", "receiver":', personAddress, 
                        '", "tokenId":', newItemId.toString(), 
                        '", "tokenURI":', tokenUri,
                        '"}'
                    )
                )
            )
        );

        merkleTree.insert(pokemonNFTInfo);

        // Increment the counter when the next NFT is minted.
        _tokenIds.increment();
        console.log("An NFT w/ ID %s has been minted to %s", newItemId, personAddress);

        // notiy the front end with this event
        emit NewNFTMinted(msg.sender, newItemId);
    }
}

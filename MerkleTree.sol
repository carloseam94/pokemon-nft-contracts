//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";

contract MerkleTree {
    bytes32[] public nodes;
    bytes32[] public leaves;
    uint256 index;

    constructor(uint256 n) {
        uint256 N = n * 2 - 1;
        index = 0;
        // initialize the nodes
        for (uint256 i = 0; i < N; i++) {
            if (i < n) {
                leaves.push(keccak256(abi.encodePacked("0x00")));
            }
            nodes.push(keccak256(abi.encodePacked("0x00")));
        }
    }

    function getNodes() public view returns (bytes32[] memory) {
        return nodes;
    }

    function getLeaves() public view returns (bytes32[] memory) {
        return leaves;
    }

    function insert(string memory x) public {
        require(index < leaves.length);

        uint256 n = leaves.length;
        uint256 i = index;
        // hash of leaf
        nodes[i] = keccak256(abi.encodePacked(x));
        leaves[i] = nodes[i];

        // go up through the branch untill the root
        uint256 N = n * 2 - 1;
        uint256 parent = i / 2 + n;
        uint256 sibling = i % 2 == 0 ? i + 1 : i - 1;
        while (parent < N) {
            nodes[parent] = keccak256(abi.encodePacked(nodes[i], nodes[sibling]));
            i = parent;
            parent = i / 2 + n;
            sibling = i % 2 == 0 ? i + 1 : i - 1;
        }

        index++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DestinationChainMock {
    uint8 public number;

    constructor() {}

    function store(uint8 _num) public returns (uint8) {
        number = _num;
        return number;
    }
}

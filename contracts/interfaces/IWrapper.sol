// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWrapper {
    function doCCTrx(
        uint256 _bridgeSelector,
        uint256 _srcChainID,
        uint256 _destChainID,
        bytes calldata _payload,
        bytes calldata _bridgeParams
    ) external payable;
}

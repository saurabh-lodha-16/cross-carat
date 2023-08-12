// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILayerZeroHelper {
    function send(
        uint16 _destinationLayerZeroChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) external payable;
}

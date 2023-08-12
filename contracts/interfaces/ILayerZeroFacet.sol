// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILayerZeroFacet {
    function useLayerZero(
        uint16 _destinationLayerZeroChainId,
        address _destinationAddress,
        bytes calldata _payload,
        bytes calldata _bridgeParams,
        uint256 _srcChainID
    ) external payable;

    function layerZeroReceive(
        uint16 _sourceLayerZeroChainId,
        bytes memory _sourceAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external;
}

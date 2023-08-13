// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHyperlaneFacet {
    function useHyperlane(
        uint32 _destinationDomain,
        address _destinationAddress,
        bytes calldata _payload,
        bytes calldata _bridgeParams,
        uint256 _srcChainID
    ) external payable;
}

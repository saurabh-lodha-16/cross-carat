// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICCIPFacet {
    function useCCIP(
        uint64 _destinationChainSelector,
        address _destinationAddress,
        bytes calldata _payload,
        bytes calldata _bridgeParams,
        uint256 _srcChainID
    ) external payable;
}

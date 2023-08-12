// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";
import {ILayerZeroFacet} from "./interfaces/ILayerZeroFacet.sol";

contract LayerZeroHelper is NonblockingLzApp {
    address public immutable diamondContract;

    // constructor requires the LayerZero endpoint and diamond contract for this chain
    constructor(address _endpoint, address _diamondContract) NonblockingLzApp(_endpoint) {
        diamondContract = _diamondContract;
    }

    function send(
        uint16 _destinationLayerZeroChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) external payable {
        require(
            msg.sender == diamondContract,
            "LayerZeroHelper: caller is not the diamond contract"
        );
        _lzSend(
            _destinationLayerZeroChainId,
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams,
            msg.value
        );
    }

    //This will be called by LayerZero and we need to forward this call to Diamond contract
    function _nonblockingLzReceive(
        uint16 _sourceLayerZeroChainId,
        bytes memory _sourceAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        ILayerZeroFacet(diamondContract).layerZeroReceive(
            _sourceLayerZeroChainId,
            _sourceAddress,
            _nonce,
            _payload
        );
    }
}

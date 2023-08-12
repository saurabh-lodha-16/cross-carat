// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {ILayerZeroHelper} from "../interfaces/ILayerZeroHelper.sol";
import {TransferHelper} from "../libraries/TransferHelper.sol";

contract LayerZeroFacet {
    using Address for address;

    string public constant BRIDGE_NAME = "LayerZero";

    // The custom LayerZeroHelper contract on this chain
    ILayerZeroHelper public immutable layerZeroHelper;

    error NotEnoughValueForGas();

    event CrossChainCalled(
        address caller,
        bytes32 id,
        string bridgeUsed,
        uint16 destinationLayerZeroChainId,
        bytes payload,
        bytes acknowledgment
    );
    event CrossChainReceived(
        address caller,
        bytes32 id,
        string bridgeUsed,
        uint16 sourceLayerZeroChainId,
        bytes payload,
        bytes acknowledgment
    );

    // constructor requires the LayerZeroHelper contract for this chain
    constructor(address _layerZeroHelper) {
        layerZeroHelper = ILayerZeroHelper(_layerZeroHelper);
    }

    function useLayerZero(
        uint16 _destinationLayerZeroChainId,
        address _destinationAddress,
        bytes calldata _payload,
        bytes calldata _bridgeParams,
        uint256 _srcChainID
    ) external payable {
        if (msg.value == 0) revert NotEnoughValueForGas();

        bytes32 id = _buildID(_srcChainID);
        (address sourceChainRefundAddress, , , bytes memory adapterParams) = abi.decode(
            _bridgeParams,
            (address, address, uint256, bytes)
        );

        bytes memory modifiedPayload = _buildModifiedPayload(_payload, id, _bridgeParams);

        layerZeroHelper.send{value: msg.value}(
            _destinationLayerZeroChainId,
            modifiedPayload,
            payable(sourceChainRefundAddress),
            address(0x0),
            adapterParams
        );

        bytes memory acknowledgment = abi.decode(modifiedPayload, (bytes));

        emit CrossChainCalled(
            tx.origin,
            id,
            BRIDGE_NAME,
            _destinationLayerZeroChainId,
            modifiedPayload,
            acknowledgment
        );
    }

    function _buildModifiedPayload(
        bytes calldata _payload,
        bytes32 _id,
        bytes calldata _bridgeParams
    ) internal pure returns (bytes memory modifiedPayload) {
        (
            bytes memory acknowledgment,
            bytes memory contractCalldata,
            address contractAddress,
            address callbackContractAddress
        ) = abi.decode(_payload, (bytes, bytes, address, address));

        modifiedPayload = abi.encode(
            acknowledgment,
            contractCalldata,
            contractAddress,
            callbackContractAddress,
            _id,
            _bridgeParams
        );
    }

    function layerZeroReceive(
        uint16 _sourceLayerZeroChainId,
        bytes memory _sourceAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external {
        require(
            msg.sender == address(layerZeroHelper),
            "LayerZeroFacet: caller is not the LayerZero App"
        );
        (
            bytes memory acknowledgment,
            ,
            ,
            address callbackContractAddress,
            bytes32 id,
            bytes memory bridgeParams
        ) = abi.decode(_payload, (bytes, bytes, address, address, bytes32, bytes));

        address sourceAddress;
        assembly {
            sourceAddress := mload(add(_sourceAddress, 20))
        }

        emit CrossChainReceived(
            sourceAddress,
            id,
            BRIDGE_NAME,
            _sourceLayerZeroChainId,
            _payload,
            acknowledgment
        );

        bool sendAck = abi.decode(acknowledgment, (bool));

        if (sendAck == true) {
            /*
            We are on destination chain.
            1. Process contract execution
            2. Send Acknowledgment back to source
            */
            _sendAcknowledgement(_sourceLayerZeroChainId, _payload, id, bridgeParams);
        } else {
            if (callbackContractAddress == address(0)) {
                /*
            We are on destination chain.
            1. Process contract execution.
            2. Acknowledgement does not need to be sent.
            */
                _processContractExecution(_payload);
            } else {
                /*
            We are on source chain.
            1. Process callback.
            */
                _processCallback(callbackContractAddress, _payload);
            }
        }
    }

    function _processContractExecution(
        bytes memory _payload
    ) internal returns (bytes memory returnData) {
        (, bytes memory contractCalldata, address contractAddress) = abi.decode(
            _payload,
            (bytes, bytes, address)
        );
        //to-do handle condition if there is no call to be done.
        //to-do What if there is no return data
        returnData = contractAddress.functionCall(contractCalldata);
    }

    function _sendAcknowledgement(
        uint16 _sourceLayerZeroChainId,
        bytes memory _payload,
        bytes32 _id,
        bytes memory _bridgeParams
    ) internal {
        bytes memory returnData = _processContractExecution(_payload);

        (
            ,
            address destinationChainRefundAddress,
            uint256 relayerFee,
            bytes memory adapterParams
        ) = abi.decode(_bridgeParams, (address, address, uint256, bytes));

        (
            bytes memory updatedAcknowledgment,
            bytes memory modifiedPayload
        ) = _buildPayloadForSendingAcknowledgement(_payload, returnData);

        require(
            address(this).balance >= relayerFee,
            "LayerZeroFacet: Not enough gas to pay for relayer fee"
        );

        layerZeroHelper.send{value: relayerFee}(
            _sourceLayerZeroChainId,
            modifiedPayload,
            payable(destinationChainRefundAddress),
            address(0x0),
            adapterParams
        );

        emit CrossChainCalled(
            address(this),
            _id,
            BRIDGE_NAME,
            _sourceLayerZeroChainId,
            modifiedPayload,
            updatedAcknowledgment
        );
    }

    function _buildPayloadForSendingAcknowledgement(
        bytes memory _payload,
        bytes memory _returnData
    ) internal pure returns (bytes memory updatedAcknowledgment, bytes memory modifiedPayload) {
        updatedAcknowledgment = abi.encode(false, _returnData);
        (
            ,
            bytes memory contractCalldata,
            address contractAddress,
            address callbackContractAddress,
            bytes32 id,
            bytes memory bridgeParams
        ) = abi.decode(_payload, (bytes, bytes, address, address, bytes32, bytes));

        modifiedPayload = abi.encode(
            updatedAcknowledgment,
            contractCalldata,
            contractAddress,
            callbackContractAddress,
            id,
            bridgeParams
        );
    }

    function _processCallback(address _callbackContractAddress, bytes memory _payload) internal {
        _callbackContractAddress.functionCall(
            abi.encodeWithSignature("callbackHandler(bytes)", _payload)
        );
    }

    function _buildID(uint256 _srcChainID) internal returns (bytes32 id) {
        id = keccak256(abi.encode(_srcChainID, LibDiamond.nonce()));
        LibDiamond.incrementNonce();
    }

    function removeNativeToken() external {
        LibDiamond.enforceIsContractOwner();
        TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }
}

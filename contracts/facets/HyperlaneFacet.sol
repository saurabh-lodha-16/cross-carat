// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import {IMailbox} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";
import {IMessageRecipient} from "@hyperlane-xyz/core/contracts/interfaces/IMessageRecipient.sol";
import {IInterchainGasPaymaster} from "@hyperlane-xyz/core/contracts/interfaces/IInterchainGasPaymaster.sol";
import {TypeCasts} from "@hyperlane-xyz/core/contracts/libs/TypeCasts.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {TransferHelper} from "../libraries/TransferHelper.sol";

contract HyperlaneFacet is IMessageRecipient {
    using Address for address;
    using TypeCasts for address;
    using TypeCasts for bytes32;

    string public constant BRIDGE_NAME = "Hyperlane";

    // The mailbox contract on this chain
    IMailbox public immutable mailbox;

    // The interchainGasPaymaster contract on this chain
    IInterchainGasPaymaster public immutable interchainGasPaymaster;

    error NotEnoughValueForGas();

    event CrossChainCalled(
        address caller,
        bytes32 id,
        string bridgeUsed,
        uint32 destinationDomain,
        bytes payload,
        bytes acknowledgment
    );
    event CrossChainReceived(
        address caller,
        bytes32 id,
        string bridgeUsed,
        uint32 sourceDomain,
        bytes payload,
        bytes acknowledgment
    );

    // for access control on handle implementations
    modifier onlyMailbox() {
        require(msg.sender == address(mailbox));
        _;
    }

    constructor(address _mailbox, address _interchainGasPaymaster) {
        mailbox = IMailbox(_mailbox);
        interchainGasPaymaster = IInterchainGasPaymaster(_interchainGasPaymaster);
    }

    function useHyperlane(
        uint32 _destinationDomain,
        address _destinationAddress,
        bytes calldata _payload,
        bytes calldata _bridgeParams,
        uint256 _srcChainID
    ) external payable {
        if (msg.value == 0) revert NotEnoughValueForGas();

        bytes32 id = _buildID(_srcChainID);

        bytes memory modifiedPayload = _buildModifiedPayload(_payload, id, _bridgeParams);

        bytes32 messageId = mailbox.dispatch(
            _destinationDomain,
            _destinationAddress.addressToBytes32(),
            modifiedPayload
        );

        address sourceChainRefundAddress = abi.decode(_bridgeParams, (address));

        _payInterchainGasPaymaster(
            messageId,
            _destinationDomain,
            _bridgeParams,
            sourceChainRefundAddress,
            msg.value
        );

        bytes memory acknowledgment = abi.decode(modifiedPayload, (bytes));

        emit CrossChainCalled(
            tx.origin,
            id,
            BRIDGE_NAME,
            _destinationDomain,
            modifiedPayload,
            acknowledgment
        );
    }

    function _payInterchainGasPaymaster(
        bytes32 _messageId,
        uint32 _destinationDomain,
        bytes memory _bridgeParams,
        address _refundAddress,
        uint256 _relayerFee
    ) internal {
        (, , , uint256 gasAmount) = abi.decode(_bridgeParams, (address, address, uint256, uint256));
        interchainGasPaymaster.payForGas{value: _relayerFee}(
            _messageId,
            _destinationDomain,
            gasAmount,
            _refundAddress
        );
    }

    function _buildModifiedPayload(
        bytes calldata _payload,
        bytes32 _id,
        bytes memory _bridgeParams
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

    function handle(
        uint32 _sourceDomain,
        bytes32 _sender,
        bytes calldata _payload
    ) external onlyMailbox {
        (
            bytes memory acknowledgment,
            ,
            ,
            address callbackContractAddress,
            bytes32 id,
            bytes memory bridgeParams
        ) = abi.decode(_payload, (bytes, bytes, address, address, bytes32, bytes));

        emit CrossChainReceived(
            _sender.bytes32ToAddress(),
            id,
            BRIDGE_NAME,
            _sourceDomain,
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
            _sendAcknowledgement(_sourceDomain, _sender, _payload, id, bridgeParams);
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
        uint32 _sourceDomain,
        bytes32 _sender,
        bytes memory _payload,
        bytes32 _id,
        bytes memory _bridgeParams
    ) internal {
        bytes memory returnData = _processContractExecution(_payload);

        (, address destinationChainRefundAddress, uint256 relayerFee) = abi.decode(
            _bridgeParams,
            (address, address, uint256)
        );

        (
            bytes memory updatedAcknowledgment,
            bytes memory modifiedPayload
        ) = _buildPayloadForSendingAcknowledgement(_payload, returnData);

        require(
            address(this).balance >= relayerFee,
            "ConnextFacet: Not enough gas to pay for relayer fee"
        );

        bytes32 messageId = mailbox.dispatch(_sourceDomain, _sender, modifiedPayload);

        _payInterchainGasPaymaster(
            messageId,
            _sourceDomain,
            _bridgeParams,
            destinationChainRefundAddress,
            relayerFee
        );

        emit CrossChainCalled(
            address(this),
            _id,
            BRIDGE_NAME,
            _sourceDomain,
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

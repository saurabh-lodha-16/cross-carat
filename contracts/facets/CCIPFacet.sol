// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract CCIPFacet is CCIPReceiver {
    using Address for address;

    string public constant BRIDGE_NAME = "CCIP";

    // The Router client contract on this chain
    IRouterClient public immutable router;

    error NotEnoughValueForGas();

    event CrossChainCalled(
        address caller,
        bytes32 id,
        string bridgeUsed,
        uint64 destinationChainSelector,
        bytes payload,
        bytes acknowledgment
    );
    event CrossChainReceived(
        address caller,
        bytes32 id,
        string bridgeUsed,
        uint64 sourceChainSelector,
        bytes payload,
        bytes acknowledgment
    );

    constructor(address _router) CCIPReceiver(_router) {
        router = IRouterClient(_router);
    }

    function useCCIP(
        uint64 _destinationChainSelector,
        address _destinationAddress,
        bytes calldata _payload,
        bytes calldata _bridgeParams,
        uint256 _srcChainID
    ) external payable {
        if (msg.value == 0) revert NotEnoughValueForGas();

        bytes32 id = _buildID(_srcChainID);
        bytes memory modifiedPayload = _buildModifiedPayload(_payload, id, _bridgeParams);

        uint256 gasAmount = abi.decode(_bridgeParams, (uint256));

        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            _destinationAddress,
            _payload,
            gasAmount
        );

        router.ccipSend{value: msg.value}(_destinationChainSelector, evm2AnyMessage);

        bytes memory acknowledgment = abi.decode(modifiedPayload, (bytes));
        emit CrossChainCalled(
            tx.origin,
            id,
            BRIDGE_NAME,
            _destinationChainSelector,
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

    function _buildCCIPMessage(
        address _destinationAddress,
        bytes memory _payload,
        uint256 _gasAmount
    ) internal pure returns (Client.EVM2AnyMessage memory evm2AnyMessage) {
        evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(_destinationAddress),
            data: _payload,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: _gasAmount, strict: false})
            ),
            feeToken: address(0)
        });
    }

    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override {
        _execute(
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address)),
            any2EvmMessage.data
        );
    }

    function _execute(
        uint64 _sourceChainSelector,
        address _sourceAddress,
        bytes memory _payload
    ) internal {
        (
            bytes memory acknowledgment,
            ,
            ,
            address callbackContractAddress,
            bytes32 id,
            bytes memory bridgeParams
        ) = abi.decode(_payload, (bytes, bytes, address, address, bytes32, bytes));
        emit CrossChainReceived(
            _sourceAddress,
            id,
            BRIDGE_NAME,
            _sourceChainSelector,
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
            _sendAcknowledgement(_sourceChainSelector, _sourceAddress, _payload, id, bridgeParams);
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
        uint64 _sourceChainSelector,
        address _sourceAddress,
        bytes memory _payload,
        bytes32 _id,
        bytes memory _bridgeParams
    ) internal {
        bytes memory returnData = _processContractExecution(_payload);

        (uint256 gasAmount, uint256 relayerFee) = abi.decode(_bridgeParams, (uint256, uint256));
        (
            bytes memory updatedAcknowledgment,
            bytes memory modifiedPayload
        ) = _buildPayloadForSendingAcknowledgement(_payload, returnData);

        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            _sourceAddress,
            modifiedPayload,
            gasAmount
        );

        router.ccipSend{value: relayerFee}(_sourceChainSelector, evm2AnyMessage);

        emit CrossChainCalled(
            address(this),
            _id,
            BRIDGE_NAME,
            _sourceChainSelector,
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
}

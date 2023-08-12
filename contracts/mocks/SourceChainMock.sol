// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IWrapper} from "../interfaces/IWrapper.sol";

contract SourceChainMock {
    IWrapper public immutable wrapper;

    event AcknowledgementReceived(bool sendAck, bytes32 id, bytes returnData);

    constructor(IWrapper _wrapper) {
        wrapper = _wrapper;
    }

    function storeOnRemote(
        bool _sendAcknowledgment,
        bytes memory _contractCalldata,
        address _destinationChainContract,
        uint256 _bridgeSelector,
        uint256 _srcChainID,
        uint256 _destChainID,
        bytes calldata _bridgeParams,
        address _callBackContractAddress
    ) external payable {
        bytes memory payload = abi.encode(
            abi.encode(_sendAcknowledgment), //acknowledgment
            _contractCalldata, //contract calldata
            _destinationChainContract, //contract address on destination chain which is to be called
            _callBackContractAddress //callback address
        );
        wrapper.doCCTrx{value: msg.value}(
            _bridgeSelector,
            _srcChainID,
            _destChainID,
            payload,
            _bridgeParams
        );
    }

    function callbackHandler(bytes calldata _payload) external {
        (bytes memory acknowledgment, , , , bytes32 id) = abi.decode(
            _payload,
            (bytes, bytes, address, address, bytes32)
        );
        (bool sendAck, bytes memory returnData) = abi.decode(acknowledgment, (bool, bytes));
        emit AcknowledgementReceived(sendAck, id, returnData);
    }
}

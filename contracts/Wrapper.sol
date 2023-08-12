// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ILayerZeroFacet} from "./interfaces/ILayerZeroFacet.sol";
import {IHyperlaneFacet} from "./interfaces/IHyperlaneFacet.sol";
import {ICCIPFacet} from "./interfaces/ICCIPFacet.sol";

contract Wrapper is Ownable, ReentrancyGuard {
    mapping(uint256 => address) public chainIDToDiamondContract;
    mapping(uint256 => uint16) public chainIDToLayerZeroChainID;
    mapping(uint256 => uint32) public chainIDToHyperlaneDomainID;
    mapping(uint256 => uint64) public chainIDToCCIPChainSelector;

    error NotEnoughValueForGas();

    //to-do params generalization
    function doCCTrx(
        uint256 _bridgeSelector,
        uint256 _srcChainID,
        uint256 _destChainID,
        bytes calldata _payload,
        bytes calldata _bridgeParams
    ) external payable {
        if (msg.value == 0) revert NotEnoughValueForGas();

        _checkPayload(_payload);

        if (_bridgeSelector == 0) {
            ILayerZeroFacet(chainIDToDiamondContract[_srcChainID]).useLayerZero{value: msg.value}(
                chainIDToLayerZeroChainID[_destChainID],
                chainIDToDiamondContract[_destChainID],
                _payload,
                _bridgeParams,
                _srcChainID
            );
        } else if (_bridgeSelector == 1) {
            IHyperlaneFacet(chainIDToDiamondContract[_srcChainID]).useHyperlane{value: msg.value}(
                chainIDToHyperlaneDomainID[_destChainID],
                chainIDToDiamondContract[_destChainID],
                _payload,
                _bridgeParams,
                _srcChainID
            );
        } else if (_bridgeSelector == 2) {
            ICCIPFacet(chainIDToDiamondContract[_srcChainID]).useCCIP{value: msg.value}(
                chainIDToCCIPChainSelector[_destChainID],
                chainIDToDiamondContract[_destChainID],
                _payload,
                _bridgeParams,
                _srcChainID
            );
        }
    }

    function _checkPayload(bytes calldata _payload) internal pure {
        //to-do confirm with Tejas about this
        (bytes memory acknowledgment, , , address callbackContractAddress) = abi.decode(
            _payload,
            (bytes, bytes, address, address)
        );
        bool sendAck = abi.decode(acknowledgment, (bool));

        if (sendAck == true) {
            require(
                callbackContractAddress != address(0),
                "Wrapper: Callback contract address should not be zero address"
            );
        } else {
            require(
                callbackContractAddress == address(0),
                "Wrapper: Callback contract address should be zero address"
            );
        }
    }

    function upsertChainIDToDiamondContract(
        uint256[] memory _chainIDs,
        address[] memory _diamondContractAddresses
    ) external onlyOwner {
        require(
            _chainIDs.length == _diamondContractAddresses.length,
            "Wrapper: Input arrays length mismatch"
        );
        for (uint256 i = 0; i < _chainIDs.length; i++) {
            require(_diamondContractAddresses[i] != address(0), "Wrapper: No zero address");
            chainIDToDiamondContract[_chainIDs[i]] = _diamondContractAddresses[i];
        }
    }

    function upsertChainIDToLayerZeroChainID(
        uint256[] memory _chainIDs,
        uint16[] memory _layerZeroChainIDs
    ) external onlyOwner {
        require(
            _chainIDs.length == _layerZeroChainIDs.length,
            "Wrapper: Input arrays length mismatch"
        );
        for (uint256 i = 0; i < _chainIDs.length; i++) {
            chainIDToLayerZeroChainID[_chainIDs[i]] = _layerZeroChainIDs[i];
        }
    }

    function upsertChainIDToHyperlaneDomainID(
        uint256[] memory _chainIDs,
        uint32[] memory _hyperlaneDomainIDs
    ) external onlyOwner {
        require(
            _chainIDs.length == _hyperlaneDomainIDs.length,
            "Wrapper: Input arrays length mismatch"
        );
        for (uint256 i = 0; i < _chainIDs.length; i++) {
            chainIDToHyperlaneDomainID[_chainIDs[i]] = _hyperlaneDomainIDs[i];
        }
    }

    function upsertChainIDToCCIPChainSelector(
        uint256[] memory _chainIDs,
        uint64[] memory _ccipChainSelectors
    ) external onlyOwner {
        require(
            _chainIDs.length == _ccipChainSelectors.length,
            "Wrapper: Input arrays length mismatch"
        );
        for (uint256 i = 0; i < _chainIDs.length; i++) {
            chainIDToCCIPChainSelector[_chainIDs[i]] = _ccipChainSelectors[i];
        }
    }
}

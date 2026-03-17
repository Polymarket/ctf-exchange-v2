// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import { ERC20 } from "lib/solady/src/tokens/ERC20.sol";
import { ERC1155 } from "lib/solady/src/tokens/ERC1155.sol";

import { ERC1155TokenReceiver } from "src/exchange/mixins/ERC1155TokenReceiver.sol";
import { IConditionalTokens } from "src/exchange/interfaces/IConditionalTokens.sol";

/// @notice Minimal adapter mock that emulates CtfCollateralAdapter behavior for tests.
contract CtfCollateralAdapterMock is ERC1155TokenReceiver {
    IConditionalTokens public immutable conditionalTokens;
    address public immutable collateralToken;
    address public immutable usdce;

    constructor(address _conditionalTokens, address _collateralToken, address _usdce) {
        conditionalTokens = IConditionalTokens(_conditionalTokens);
        collateralToken = _collateralToken;
        usdce = _usdce;

        ERC20(_usdce).approve(_conditionalTokens, type(uint256).max);
    }

    function splitPosition(address, bytes32, bytes32 conditionId, uint256[] calldata, uint256 amount) external {
        ERC20(collateralToken).transferFrom(msg.sender, address(this), amount);

        conditionalTokens.splitPosition(usdce, bytes32(0), conditionId, _partition(), amount);

        uint256[] memory positionIds = _getPositionIds(conditionId);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        amounts[1] = amount;

        ERC1155(address(conditionalTokens)).safeBatchTransferFrom(address(this), msg.sender, positionIds, amounts, "");
    }

    function mergePositions(address, bytes32, bytes32 conditionId, uint256[] calldata, uint256 amount) external {
        uint256[] memory positionIds = _getPositionIds(conditionId);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        amounts[1] = amount;

        ERC1155(address(conditionalTokens)).safeBatchTransferFrom(msg.sender, address(this), positionIds, amounts, "");

        conditionalTokens.mergePositions(usdce, bytes32(0), conditionId, _partition(), amount);

        ERC20(collateralToken).transfer(msg.sender, amount);
    }

    function _getPositionIds(bytes32 conditionId) internal view returns (uint256[] memory positionIds) {
        positionIds = new uint256[](2);
        bytes32 yesCollection = conditionalTokens.getCollectionId(bytes32(0), conditionId, 2);
        bytes32 noCollection = conditionalTokens.getCollectionId(bytes32(0), conditionId, 1);
        positionIds[0] = conditionalTokens.getPositionId(usdce, yesCollection);
        positionIds[1] = conditionalTokens.getPositionId(usdce, noCollection);
    }

    function _partition() internal pure returns (uint256[] memory partition) {
        partition = new uint256[](2);
        partition[0] = 1;
        partition[1] = 2;
    }
}

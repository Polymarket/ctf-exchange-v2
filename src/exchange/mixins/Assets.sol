// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { ERC20 } from "lib/solady/src/tokens/ERC20.sol";
import { ERC1155 } from "lib/solady/src/tokens/ERC1155.sol";

import { IAssets } from "../interfaces/IAssets.sol";

abstract contract Assets is IAssets {
    /// @notice The Collateral token address
    address internal immutable collateral;

    /// @notice The Conditional Tokens Framework address
    address internal immutable ctf;

    /// @notice The address that facilitates Outcome Token minting or merging
    address internal immutable outcomeTokenFactory;

    constructor(address _collateral, address _ctf, address _outcomeTokenFactory) {
        collateral = _collateral;
        ctf = _ctf;
        outcomeTokenFactory = _outcomeTokenFactory;
        ERC20(_collateral).approve(_outcomeTokenFactory, type(uint256).max);
        ERC1155(_ctf).setApprovalForAll(_outcomeTokenFactory, true);
    }

    function getCollateral() public view override returns (address) {
        return collateral;
    }

    function getCtf() public view override returns (address) {
        return ctf;
    }

    function getOutcomeTokenFactory() public view override returns (address) {
        return outcomeTokenFactory;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

interface IFeesEE {
    error MaxFeeExceeded();

    /// @notice Emitted when a fee is charged
    event FeeCharged(address indexed receiver, uint256 tokenId, uint256 amount);
}

abstract contract IFees is IFeesEE {
    function validateOrderFee(uint256 maxFee, uint256 fee) public view virtual;
}

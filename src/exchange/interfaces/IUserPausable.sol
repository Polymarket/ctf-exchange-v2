// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;


/**
abstract contract IRegistry is IRegistryEE {
    function getConditionId(uint256 tokenId) public view virtual returns (bytes32);

    function getComplement(uint256 tokenId) public view virtual returns (uint256);

    function validateTokenId(uint256 tokenId) public view virtual;

    function validateComplement(uint256 token0, uint256 token1) public view virtual;
}
*/
interface IUserPausableEE {
    error UserIsPaused();

    /// @notice Emitted when a user pauses their account
    event UserPaused(address indexed usr);

    /// @notice Emitted when a user unpauses their account
    event UserUnpaused(address indexed usr);
}

abstract contract IUserPausable is IUserPausableEE {
    function isPaused(address usr) public view virtual returns (bool);

    function pauseUser() external virtual;

    function unpauseUser() external virtual;
}


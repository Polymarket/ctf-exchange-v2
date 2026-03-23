// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.34;

import { ERC20 } from "@solady/src/tokens/ERC20.sol";
import { Ownable } from "@solady/src/auth/Ownable.sol";

/// @notice Mock CollateralVault for testing.
contract CollateralVault is Ownable {
    constructor(address _owner) {
        _initializeOwner(_owner);
    }

    function approve(address _token, address _spender, uint256 _amount) external onlyOwner {
        ERC20(_token).approve(_spender, _amount);
    }
}

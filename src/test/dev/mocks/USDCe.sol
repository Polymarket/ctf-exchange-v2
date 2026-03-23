// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { ERC20 } from "@solady/src/tokens/ERC20.sol";

contract USDCe is ERC20 {
    function name() public pure override returns (string memory) {
        return "USDCe";
    }

    function symbol() public pure override returns (string memory) {
        return "USDCe";
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        _burn(_from, _amount);
    }
}

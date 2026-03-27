// SPDX-License-Identifier: BUSL-1.1
pragma solidity <0.9.0;

import { Order } from "../libraries/Structs.sol";

abstract contract IHashing {
    function hashOrder(Order memory order) public view virtual returns (bytes32);
}

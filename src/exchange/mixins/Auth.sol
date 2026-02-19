// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IAuth } from "../interfaces/IAuth.sol";

/// @title Auth
/// @notice Provides admin and operator roles and access control modifiers
abstract contract Auth is IAuth {
    /// @dev The set of addresses authorized as Admins
    mapping(address => uint256) internal admins;

    /// @dev The set of addresses authorized as Operators
    mapping(address => uint256) internal operators;

    modifier onlyAdmin() {
        require(admins[msg.sender] == 1, NotAdmin());
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender] == 1, NotOperator());
        _;
    }

    constructor(address admin) {
        admins[admin] = 1;
        operators[admin] = 1;
    }

    function isAdmin(address usr) external view returns (bool) {
        return admins[usr] == 1;
    }

    function isOperator(address usr) external view returns (bool) {
        return operators[usr] == 1;
    }

    /// @notice Adds a new admin
    /// Can only be called by a current admin
    /// @param admin_ - The new admin
    function addAdmin(address admin_) external onlyAdmin {
        admins[admin_] = 1;
        emit NewAdmin(admin_, msg.sender);
    }

    /// @notice Adds a new operator
    /// Can only be called by a current admin
    /// @param operator_ - The new operator
    function addOperator(address operator_) external onlyAdmin {
        operators[operator_] = 1;
        emit NewOperator(operator_, msg.sender);
    }

    /// @notice Removes an existing Admin
    /// Can only be called by a current admin
    /// @param admin - The admin to be removed
    function removeAdmin(address admin) external onlyAdmin {
        admins[admin] = 0;
        emit RemovedAdmin(admin, msg.sender);
    }

    /// @notice Removes an existing operator
    /// Can only be called by a current admin
    /// @param operator - The operator to be removed
    function removeOperator(address operator) external onlyAdmin {
        operators[operator] = 0;
        emit RemovedOperator(operator, msg.sender);
    }

    /// @notice Removes the admin role for the caller
    /// Can only be called by an existing admin
    function renounceAdminRole() external onlyAdmin {
        admins[msg.sender] = 0;
        emit RemovedAdmin(msg.sender, msg.sender);
    }

    /// @notice Removes the operator role for the caller
    /// Can only be called by an exiting operator
    function renounceOperatorRole() external onlyOperator {
        operators[msg.sender] = 0;
        emit RemovedOperator(msg.sender, msg.sender);
    }
}

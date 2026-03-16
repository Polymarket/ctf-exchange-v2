// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IAuth } from "../interfaces/IAuth.sol";

/// @title Auth
/// @notice Provides admin and operator roles and access control modifiers
abstract contract Auth is IAuth {
    /// @dev The set of addresses authorized as Admins
    mapping(address => bool) internal admins;

    /// @dev The number of active admins
    uint256 internal adminCount;

    /// @dev The set of addresses authorized as Operators
    mapping(address => bool) internal operators;

    modifier onlyAdmin() {
        require(admins[msg.sender], NotAdmin());
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], NotOperator());
        _;
    }

    constructor(address admin) {
        admins[admin] = true;
        adminCount = 1;
        operators[admin] = true;
    }

    function isAdmin(address usr) external view returns (bool) {
        return admins[usr];
    }

    function isOperator(address usr) external view returns (bool) {
        return operators[usr];
    }

    /// @notice Adds a new admin
    /// Can only be called by a current admin
    /// @param admin_ - The new admin
    function addAdmin(address admin_) external onlyAdmin {
        require(!admins[admin_], AlreadyAdmin());
        ++adminCount;
        admins[admin_] = true;
        emit NewAdmin(admin_, msg.sender);
    }

    /// @notice Adds a new operator
    /// Can only be called by a current admin
    /// @param operator_ - The new operator
    function addOperator(address operator_) external onlyAdmin {
        require(!operators[operator_], AlreadyOperator());
        operators[operator_] = true;
        emit NewOperator(operator_, msg.sender);
    }

    /// @notice Removes an existing Admin
    /// Can only be called by a current admin
    /// @param admin - The admin to be removed
    function removeAdmin(address admin) external onlyAdmin {
        require(admins[admin], NotAdmin());
        require(adminCount > 1, LastAdmin());
        --adminCount;
        admins[admin] = false;
        emit RemovedAdmin(admin, msg.sender);
    }

    /// @notice Removes an existing operator
    /// Can only be called by a current admin
    /// @param operator - The operator to be removed
    function removeOperator(address operator) external onlyAdmin {
        require(operators[operator], NotOperator());
        operators[operator] = false;
        emit RemovedOperator(operator, msg.sender);
    }

    /// @notice Removes the operator role for the caller
    /// @dev Can only be called by an existing operator
    function renounceOperatorRole() external onlyOperator {
        operators[msg.sender] = false;
        emit RemovedOperator(msg.sender, msg.sender);
    }
}

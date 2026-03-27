// SPDX-License-Identifier: BUSL-1.1
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

    constructor(address _admin) {
        admins[_admin] = true;
        adminCount = 1;
        operators[_admin] = true;
    }

    /// @notice Returns whether an address is an admin
    /// @param _usr The address to check
    function isAdmin(address _usr) external view returns (bool) {
        return admins[_usr];
    }

    /// @notice Returns whether an address is an operator
    /// @param _usr The address to check
    function isOperator(address _usr) external view returns (bool) {
        return operators[_usr];
    }

    /// @notice Adds a new admin
    /// Can only be called by a current admin
    /// @param _admin - The new admin
    function addAdmin(address _admin) external onlyAdmin {
        require(!admins[_admin], AlreadyAdmin());
        ++adminCount;
        admins[_admin] = true;
        emit NewAdmin(_admin, msg.sender);
    }

    /// @notice Adds a new operator
    /// Can only be called by a current admin
    /// @param _operator - The new operator
    function addOperator(address _operator) external onlyAdmin {
        require(!operators[_operator], AlreadyOperator());
        operators[_operator] = true;
        emit NewOperator(_operator, msg.sender);
    }

    /// @notice Removes an existing Admin
    /// Can only be called by a current admin
    /// @param _admin - The admin to be removed
    function removeAdmin(address _admin) external onlyAdmin {
        require(admins[_admin], NotAdmin());
        require(adminCount > 1, LastAdmin());
        --adminCount;
        admins[_admin] = false;
        emit RemovedAdmin(_admin, msg.sender);
    }

    /// @notice Removes an existing operator
    /// Can only be called by a current admin
    /// @param _operator - The operator to be removed
    function removeOperator(address _operator) external onlyAdmin {
        require(operators[_operator], NotOperator());
        operators[_operator] = false;
        emit RemovedOperator(_operator, msg.sender);
    }

    /// @notice Removes the operator role for the caller
    /// @dev Can only be called by an existing operator
    function renounceOperatorRole() external onlyOperator {
        operators[msg.sender] = false;
        emit RemovedOperator(msg.sender, msg.sender);
    }
}

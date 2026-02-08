// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { Test } from "lib/forge-std/src/Test.sol";
import { Vm } from "lib/forge-std/src/Vm.sol";
import { PolyProxyLib } from "src/exchange/libraries/PolyProxyLib.sol";

contract MockProxyImplementation {
    uint256 public constant VALUE_TO_SET = 777;

    uint256 public value;

    event CloneConstructorCalled(address indexed caller, bytes data);

    function cloneConstructor(bytes memory data) external {
        emit CloneConstructorCalled(msg.sender, data);
    }

    function setValue(uint256 newValue) external {
        value = newValue;
    }
}

contract MinimalProxyImplementation {
    event CloneConstructorCalled(address indexed caller, bytes data);

    function cloneConstructor(bytes memory data) external {
        emit CloneConstructorCalled(msg.sender, data);
    }
}

contract PolyProxyFactoryHarness {
    error DeploymentFailed();

    event CloneConstructorRan(address indexed wallet, bytes data);

    /// @notice Deploys a minimal proxy using CREATE2 with a deterministic address
    /// @param implementation The implementation contract address to proxy to
    /// @param signer The signer address used as salt for deterministic deployment
    /// @return proxy The deployed proxy contract address
    /// @dev Uses CREATE2 assembly to deploy at a deterministic address based on the signer salt.
    ///      The creation code includes the factory address and implementation address embedded in bytecode.
    function deployProxy(address implementation, address signer) external returns (address proxy) {
        bytes memory creationCode = _constructCreationCode(implementation);
        bytes32 salt = keccak256(abi.encodePacked(signer));
        assembly {
            proxy := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        if (proxy == address(0)) revert DeploymentFailed();
    }

    function getCreationCode(address implementation) external view returns (bytes memory) {
        return _constructCreationCode(implementation);
    }

    function _constructCreationCode(address target) internal view returns (bytes memory clone) {
        address deployer = address(this);
        assembly ("memory-safe") {
            // Allocate from free memory pointer: 32 (length) + 167 (data) = 199 total
            clone := mload(64)
            mstore(64, add(clone, 199))
            mstore(clone, 167)

            // Write buffer section (99 bytes)
            // Bytes 0-31: first byte 0x3d, then 31 zero bytes
            mstore(add(clone, 32), 0x3d00000000000000000000000000000000000000000000000000000000000000)
            // Bytes 1-32: OR 12-byte prefix (with trailing zeros) with 20-byte deployer
            mstore(add(clone, 33), or(0x3d606380380380913d393d730000000000000000000000000000000000000000, deployer))
            // Bytes 33-64: 19 non-zero bytes of bytecode, then 13 zero bytes
            mstore(add(clone, 65), 0x5af4602a57600080fd5b602d8060366000396000000000000000000000000000)
            // Bytes 65-96: OR 12-byte prefix (with leading zeros) with 20-byte target
            mstore(add(clone, 84), or(0x00f3363d3d373d3d3d363d730000000000000000000000000000000000000000, target))
            // Bytes 96-127: remaining bytes of buffer + start of consData
            mstore(add(clone, 116), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            // Write consData section (68 bytes)
            mstore(add(clone, 131), 0x52e831dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(clone, 135), 0x0000000000000000000000000000000000000000000000000000000000000020)
            mstore(add(clone, 167), 0x0000000000000000000000000000000000000000000000000000000000000000)
        }
    }

    function cloneConstructor(bytes memory data) external {
        emit CloneConstructorRan(msg.sender, data);
    }
}

contract PolyProxyLibTest is Test {
    PolyProxyFactoryHarness internal factory;
    MockProxyImplementation internal implementation;

    function setUp() public {
        factory = new PolyProxyFactoryHarness();
        implementation = new MockProxyImplementation();
    }

    function test_getProxyWalletAddressMatchesManualDerivation() public {
        address signer = makeAddr("manual-derivation");
        address predicted = PolyProxyLib.getProxyWalletAddress(signer, address(implementation), address(factory));

        address expected = _manualCreate2(signer, address(implementation));
        assertEq(predicted, expected);
    }

    function test_canDeployMinimalImplementation() public {
        MinimalProxyImplementation simpleImpl = new MinimalProxyImplementation();
        address signer = makeAddr("simple-deployment");
        address predicted = PolyProxyLib.getProxyWalletAddress(signer, address(simpleImpl), address(factory));

        vm.recordLogs();
        address deployed = factory.deployProxy(address(simpleImpl), signer);
        assertEq(deployed, predicted, "create2 mismatch");
        _assertInitializerLog(deployed);
    }

    /// @notice Tests that proxy deployment matches predicted address and correctly delegates calls
    /// @dev Verifies:
    ///      1. Predicted address matches deployed address (CREATE2 determinism)
    ///      2. Proxy correctly delegates calls to implementation (delegatecall works)
    ///      3. Initializer was called during deployment (event log verification)
    function testProxyDeploymentMatchesPredictionAndDelegates() public {
        address signer = makeAddr("deployment-check");
        address predicted = PolyProxyLib.getProxyWalletAddress(signer, address(implementation), address(factory));

        vm.recordLogs();
        assertEq(predicted.code.length, 0, "proxy already deployed");
        address deployed = factory.deployProxy(address(implementation), signer);

        assertEq(deployed, predicted, "create2 mismatch");
        assertEq(MockProxyImplementation(deployed).value(), 0, "unexpected default value");

        uint256 updated = 1337;
        MockProxyImplementation(deployed).setValue(updated);
        assertEq(MockProxyImplementation(deployed).value(), updated, "delegatecall failed");

        _assertInitializerLog(deployed);
    }

    /// @notice Tests that the creation code correctly embeds factory and implementation addresses
    /// @dev Verifies that the minimal proxy creation code contains both the factory address
    ///      (deployer) and implementation address embedded in the bytecode, which is necessary
    ///      for the proxy to correctly delegate calls to the implementation.
    function test_computeCreationCodeEmbedsDependencies() public view {
        bytes memory creationCode = factory.getCreationCode(address(implementation));
        bytes memory constructorData = abi.encodeWithSignature("cloneConstructor(bytes)", new bytes(0));
        uint256 bufferLength = 99;

        assertEq(creationCode.length, bufferLength + constructorData.length, "unexpected creation code length");
        assertTrue(_containsAddress(creationCode, address(factory)), "missing factory address");
        assertTrue(_containsAddress(creationCode, address(implementation)), "missing implementation address");
    }

    function test_vmGetCodeDoesNotExposeProxyCreationCode() public view {
        bytes memory creationCode = factory.getCreationCode(address(implementation));
        bytes memory artifactCode = vm.getCode("src/exchange/libraries/PolyProxyLib.sol:PolyProxyLib");

        assertTrue(creationCode.length > 0, "creation code empty");
        assertTrue(artifactCode.length > 0, "artifact missing");
        assertTrue(
            keccak256(creationCode) != keccak256(artifactCode), "artifact unexpectedly matches proxy creation code"
        );
    }

    /// @notice Verifies that the CloneConstructorRan event was emitted correctly during proxy deployment
    /// @param deployed The address of the deployed proxy contract
    /// @dev Searches through recorded logs to find the CloneConstructorRan event and validates:
    ///      - The event was emitted by the deployed proxy
    ///      - The first indexed parameter (wallet) matches the factory address
    ///      - The event data matches the expected empty bytes payload
    function _assertInitializerLog(address deployed) internal view {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 selector = keccak256("CloneConstructorRan(address,bytes)");
        bool found;

        for (uint256 i = 0; i < logs.length; i++) {
            Vm.Log memory entry = logs[i];
            if (entry.topics.length == 0 || entry.topics[0] != selector) continue;
            found = true;
            assertEq(entry.emitter, deployed, "log emitted by unexpected contract");
            address wallet = address(uint160(uint256(entry.topics[1])));
            assertEq(wallet, address(factory), "initializer logged wrong wallet");
            assertEq(keccak256(entry.data), keccak256(abi.encode(new bytes(0))), "initializer payload mismatch");
            break;
        }

        assertTrue(found, "initializer log not found");
    }

    /// @notice Manually computes the CREATE2 address for a proxy deployment
    /// @param signer The signer address used as salt
    /// @param implementationAddress The implementation contract address
    /// @return The computed CREATE2 address
    /// @dev Implements the CREATE2 address formula: keccak256(0xff || deployer || salt || keccak256(creationCode))
    ///      This is used to verify that PolyProxyLib.getProxyWalletAddress computes addresses correctly.
    function _manualCreate2(address signer, address implementationAddress) internal view returns (address) {
        bytes memory creationCode = factory.getCreationCode(implementationAddress);
        bytes32 salt = keccak256(abi.encodePacked(signer));
        bytes32 bytecodeHash = keccak256(creationCode);
        bytes32 digest = keccak256(abi.encodePacked(bytes1(0xff), address(factory), salt, bytecodeHash));
        return address(uint160(uint256(digest)));
    }

    /// @notice Checks if a byte array contains a specific address
    /// @param data The byte array to search in
    /// @param needle The address to search for
    /// @return True if the address is found in the byte array, false otherwise
    /// @dev Performs a naive substring search by sliding through the data array
    ///      and comparing each possible position with the encoded address (20 bytes).
    function _containsAddress(bytes memory data, address needle) internal pure returns (bool) {
        bytes memory encoded = abi.encodePacked(needle);
        if (encoded.length == 0 || data.length < encoded.length) return false;

        for (uint256 i = 0; i <= data.length - encoded.length; i++) {
            bool matchFound = true;
            for (uint256 j = 0; j < encoded.length; j++) {
                if (data[i + j] != encoded[j]) {
                    matchFound = false;
                    break;
                }
            }
            if (matchFound) return true;
        }
        return false;
    }
}

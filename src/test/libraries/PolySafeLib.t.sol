// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { Test } from "lib/forge-std/src/Test.sol";
import { Vm } from "lib/forge-std/src/Vm.sol";

import { PolySafeLib } from "src/exchange/libraries/PolySafeLib.sol";

contract MockSafeImplementation {
    // Intentionally empty: acts as a stand-in for the real Gnosis Safe master copy.
}

contract PolySafeFactoryHarness {
    error DeploymentFailed();

    event SafeDeployed(address indexed safe, bytes32 indexed salt);

    /// @notice Deploys the proxy using CREATE2 and the provided signer as salt input
    /// @dev Reverts when the CREATE2 call fails (e.g. duplicate salt).
    function deploySafe(address implementation, address signer) external returns (address safe) {
        bytes memory creationCode = PolySafeLib.getContractBytecode(implementation);
        bytes32 salt = keccak256(abi.encode(signer));
        assembly {
            safe := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        if (safe == address(0)) revert DeploymentFailed();
        emit SafeDeployed(safe, salt);
    }
}

contract PolySafeLibTest is Test {
    PolySafeFactoryHarness internal factory;
    MockSafeImplementation internal implementation;

    function setUp() public {
        factory = new PolySafeFactoryHarness();
        implementation = new MockSafeImplementation();
    }

    function test_getSafeAddressMatchesManualDerivation() public {
        address signer = makeAddr("safe-manual");
        address predicted = PolySafeLib.getSafeAddress(signer, address(implementation), address(factory));

        address expected = _manualPrediction(signer, address(implementation));
        assertEq(predicted, expected, "manual create2 mismatch");
    }

    function test_SafeDeploymentMatchesPredictionAndPersistsSingleton() public {
        address signer = makeAddr("safe-deploy");
        address predicted = PolySafeLib.getSafeAddress(signer, address(implementation), address(factory));

        vm.recordLogs();
        address deployed = factory.deploySafe(address(implementation), signer);

        assertEq(deployed, predicted, "create2 mismatch");

        address singleton = address(uint160(uint256(vm.load(deployed, bytes32(uint256(0))))));
        assertEq(singleton, address(implementation), "singleton storage mismatch");

        bytes32 salt = keccak256(abi.encode(signer));
        _assertDeploymentLog(deployed, salt);
    }

    function test_getContractBytecodeReflectsImplementationAddress() public {
        bytes memory creationCode = PolySafeLib.getContractBytecode(address(implementation));
        bytes memory suffix = abi.encode(address(implementation));
        assertTrue(creationCode.length > suffix.length, "creation code shorter than suffix");

        bytes memory tail = _sliceTail(creationCode, suffix.length);
        assertEq(keccak256(tail), keccak256(suffix), "implementation suffix mismatch");

        MockSafeImplementation another = new MockSafeImplementation();

        bytes32 firstHash = keccak256(PolySafeLib.getContractBytecode(address(implementation)));
        bytes32 secondHash = keccak256(PolySafeLib.getContractBytecode(address(another)));

        assertTrue(firstHash != secondHash, "hash should change when master copy changes");
    }

    /// @notice Manually reconstructs the CREATE2 address for comparison assertions
    function _manualPrediction(address signer, address masterCopy) internal view returns (address) {
        bytes memory creationCode = PolySafeLib.getContractBytecode(masterCopy);
        bytes32 salt = keccak256(abi.encode(signer));
        bytes32 bytecodeHash = keccak256(creationCode);
        bytes32 digest = keccak256(abi.encodePacked(bytes1(0xff), address(factory), salt, bytecodeHash));
        return address(uint160(uint256(digest)));
    }

    /// @notice Returns the last `length` bytes of `data`
    function _sliceTail(bytes memory data, uint256 length) internal pure returns (bytes memory slice) {
        require(length <= data.length, "slice exceeds buffer");
        slice = new bytes(length);
        uint256 start = data.length - length;
        for (uint256 i = 0; i < length; i++) {
            slice[i] = data[start + i];
        }
    }

    /// @notice Ensures the SafeDeployed event was emitted with the expected payload
    function _assertDeploymentLog(address deployed, bytes32 salt) internal {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 deploySelector = keccak256("SafeDeployed(address,bytes32)");
        bool sawDeploy;

        for (uint256 i = 0; i < logs.length; i++) {
            Vm.Log memory entry = logs[i];
            if (entry.topics.length == 0) continue;

            if (entry.topics[0] == deploySelector) {
                sawDeploy = true;
                assertEq(entry.emitter, address(factory), "deploy log emitter mismatch");
                assertEq(entry.topics[1], bytes32(uint256(uint160(deployed))), "proxy mismatch in log");
                assertEq(entry.topics[2], salt, "salt mismatch in log");
            }
        }

        assertTrue(sawDeploy, "deployment log missing");
    }
}


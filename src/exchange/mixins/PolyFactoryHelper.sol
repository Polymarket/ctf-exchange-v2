// SPDX-License-Identifier: BUSL-1.1
pragma solidity <0.9.0;

import { PolySafeLib } from "../libraries/PolySafeLib.sol";
import { PolyProxyLib } from "../libraries/PolyProxyLib.sol";

interface IPolyProxyFactory {
    function getImplementation() external view returns (address);
}

interface IPolySafeFactory {
    function masterCopy() external view returns (address);
}

abstract contract PolyFactoryHelper {
    /// @notice The Polymarket Proxy Wallet Factory Contract
    address internal immutable proxyFactory;
    /// @notice The Polymarket Proxy Wallet Implementation Contract
    address internal immutable proxyImplementation;
    /// @notice The Polymarket Gnosis Safe Factory Contract
    address internal immutable safeFactory;
    /// @notice The Polymarket Gnosis Safe Implementation Contract
    address internal immutable safeImplementation;
    /// @notice Pre-computed keccak256 of the safe proxy creation code with the implementation
    bytes32 internal immutable safeBytecodeHash;

    constructor(address _proxyFactory, address _safeFactory) {
        proxyFactory = _proxyFactory;
        safeFactory = _safeFactory;

        proxyImplementation = IPolyProxyFactory(_proxyFactory).getImplementation();

        address _safeImpl = IPolySafeFactory(_safeFactory).masterCopy();
        safeImplementation = _safeImpl;
        safeBytecodeHash = PolySafeLib.computeBytecodeHash(_safeImpl);
    }

    /// @notice Gets the Proxy factory address
    function getProxyFactory() public view returns (address) {
        return proxyFactory;
    }

    /// @notice Gets the Safe factory address
    function getSafeFactory() public view returns (address) {
        return safeFactory;
    }

    /// @notice Gets the Proxy implementation address
    function getProxyImplementation() public view returns (address) {
        return proxyImplementation;
    }

    /// @notice Gets the Safe implementation address
    function getSafeImplementation() public view returns (address) {
        return safeImplementation;
    }

    /// @notice Gets the Polymarket proxy wallet address for an address
    /// @param _addr    - The address that owns the proxy wallet
    function getProxyWalletAddress(address _addr) public view returns (address) {
        return PolyProxyLib.getProxyWalletAddress(_addr, proxyImplementation, proxyFactory);
    }

    /// @notice Gets the Polymarket Gnosis Safe address for an address
    /// @param _addr    - The Safe owner/signer address used to derive the Safe address
    function getSafeWalletAddress(address _addr) public view returns (address) {
        return PolySafeLib.getSafeWalletAddress(_addr, safeBytecodeHash, safeFactory);
    }
}

// SPDX-License-Identifier: MIT
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
    address internal immutable polyProxyImplementation;
    /// @notice The Polymarket Gnosis Safe Factory Contract
    address internal immutable safeFactory;

    constructor(address _proxyFactory, address _safeFactory) {
        proxyFactory = _proxyFactory;
        safeFactory = _safeFactory;

        polyProxyImplementation = IPolyProxyFactory(_proxyFactory).getImplementation();
    }

    /// @notice Gets the Proxy factory address
    function getProxyFactory() public view returns (address) {
        return proxyFactory;
    }

    /// @notice Gets the Safe factory address
    function getSafeFactory() public view returns (address) {
        return safeFactory;
    }

    /// @notice Gets the Polymarket Proxy factory implementation address
    function getPolyProxyFactoryImplementation() public view returns (address) {
        return IPolyProxyFactory(proxyFactory).getImplementation();
    }

    /// @notice Gets the Safe factory implementation address
    function getSafeFactoryImplementation() public view returns (address) {
        return IPolySafeFactory(safeFactory).masterCopy();
    }

    /// @notice Gets the Polymarket proxy wallet address for an address
    /// @param _addr    - The address that owns the proxy wallet
    function getPolyProxyWalletAddress(address _addr) public view returns (address) {
        return PolyProxyLib.getProxyWalletAddress(_addr, polyProxyImplementation, proxyFactory);
    }

    /// @notice Gets the Polymarket Gnosis Safe address for an address
    /// @param _addr    - The address that owns the proxy wallet
    function getSafeAddress(address _addr) public view returns (address) {
        return PolySafeLib.getSafeAddress(_addr, getSafeFactoryImplementation(), safeFactory);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

struct ExchangeInitParams {
    /// @notice The collateral token address
    address collateral;
    /// @notice The Conditional Tokens Framework address
    address ctf;
    /// @notice The Polymarket proxy factory address
    address proxyFactory;
    /// @notice The Polymarket Gnosis Safe factory address
    address safeFactory;
    /// @notice The address which will receive fees
    address feeReceiver;
}

bytes32 constant ORDER_TYPEHASH = keccak256(
    "Order(uint256 salt,address maker,address signer,address taker,uint256 tokenId,uint256 makerAmount,uint256 takerAmount,uint256 expiration,uint256 maxFee,uint8 side,uint8 signatureType,uint256 timestamp,bytes32 metadata,bytes32 builder)"
);

struct Order {
    /// @notice Unique salt to ensure entropy
    uint256 salt;
    /// @notice Maker of the order, i.e the source of funds for the order
    address maker;
    /// @notice Signer of the order
    address signer;
    /// @notice Address of the order taker. The zero address is used to indicate a public order
    address taker;
    /// @notice Token Id of the CTF ERC1155 asset to be bought or sold
    /// If BUY, this is the tokenId of the asset to be bought, i.e the makerAssetId
    /// If SELL, this is the tokenId of the asset to be sold, i.e the takerAssetId
    uint256 tokenId;
    /// @notice Maker amount, i.e the maximum amount of tokens to be sold
    uint256 makerAmount;
    /// @notice Taker amount, i.e the minimum amount of tokens to be received
    uint256 takerAmount;
    /// @notice Unix timestamp in seconds after which the order is expired
    uint256 expiration;
    /// @notice The maximum fee that can be charged to the order
    uint256 maxFee;
    /// @notice The side of the order: BUY or SELL
    Side side;
    /// @notice Signature type used by the Order: EOA, POLY_PROXY, POLY_GNOSIS_SAFE or POLY_1271
    SignatureType signatureType;
    /// @notice Unix Timestamp in seconds at which the order was created
    uint256 timestamp;
    /// @notice The metadata associated with the order, hashed
    bytes32 metadata;
    /// @notice The builder code associated with the order, indicating its origin
    bytes32 builder;
    /// @notice The order signature
    bytes signature;
}

/// @notice Represents an order without a signature
/// Used for order hashing to avoid stack-too-deep errors
struct UnsignedOrder {
    uint256 salt;
    address maker;
    address signer;
    address taker;
    uint256 tokenId;
    uint256 makerAmount;
    uint256 takerAmount;
    uint256 expiration;
    uint256 maxFee;
    Side side;
    SignatureType signatureType;
    uint256 timestamp;
    bytes32 metadata;
    bytes32 builder;
}

enum SignatureType {
    // 0: ECDSA EIP712 signatures signed by EOAs
    EOA,
    // 1: EIP712 signatures signed by EOAs that own Polymarket Proxy wallets
    POLY_PROXY,
    // 2: EIP712 signatures signed by EOAs that own Polymarket Gnosis safes
    POLY_GNOSIS_SAFE,
    // 3: EIP1271 signatures signed by smart contracts. To be used by smart contract wallets or vaults
    POLY_1271
}

enum Side {
    // 0: buy
    BUY,
    // 1: sell
    SELL
}

enum MatchType {
    // 0: buy vs sell
    COMPLEMENTARY,
    // 1: both buys
    MINT,
    // 2: both sells
    MERGE
}

struct OrderStatus {
    bool filled;
    uint256 remaining;
}

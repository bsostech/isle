// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IPoolConfiguratorEvents {
    /// @notice Emitted when a pool configurator is initialized
    /// @param poolAdmin_ The address of the pool admin
    /// @param asset_ The address of the asset
    /// @param pool_ The address of the pool
    event Initialized(address indexed poolAdmin_, address indexed asset_, address pool_);

    /// @notice Emitted when a pool buyer is assigned
    /// @param buyer_ The address of the buyer for this pool
    event PoolBuyerAssign(address indexed buyer_);

    /// @notice Emitted when a valid seller is set
    /// @param seller_ The address of the seller
    /// @param isValid_ Whether the seller is valid
    event ValidSellerSet(address indexed seller_, bool isValid_);

    /// @notice Emitted when a valid lender is set
    /// @param lender_ The address of the lender
    /// @param isValid_ Whether the lender is valid
    event ValidLenderSet(address indexed lender_, bool isValid_);

    /// @notice Emitted when an admin fee rate is set
    /// @param adminFee_ The new admin fee rate
    event AdminFeeSet(uint256 adminFee_);

    /// @notice Emitted when the pool is set as open to the public
    /// @param isOpenToPublic_ Whether the pool is open to the public
    event OpenToPublicSet(bool isOpenToPublic_);

    /// @notice Emitted when the grace period of the pool is set
    /// @param gracePeriod_ The new grace period
    event GracePeriodSet(uint256 gracePeriod_);

    /// @notice Emitted when the base rate of the pool is set
    /// @param baseRate_ The new base rate
    event BaseRateSet(uint96 baseRate_);

    /// @notice Emitted when a redeem is processed
    /// @param owner_ The address of the owner
    /// @param redeemableShares_ The amount of redeemable shares
    /// @param resultingAssets_ The amount of assets resulting from the redeem
    event RedeemProcessed(address indexed owner_, uint256 redeemableShares_, uint256 resultingAssets_);

    /// @notice Emitted when the pool cover is deposited
    /// @param amount_ The amount of cover deposited
    event CoverDeposited(uint256 amount_);

    /// @notice Emitted when the pool cover is withdrawn
    /// @param amount_ The amount of cover withdrawn
    event CoverWithdrawn(uint256 amount_);

    /// @notice Emitted when an owner requests a redemption
    /// @param owner_ The address of the owner
    /// @param shares_ The amount of shares that is used to request for redemption
    event RedeemRequested(address indexed owner_, uint256 shares_);

    /// @notice Emitted when an owner removes shares from their withdrawal request
    /// @param owner_ The address of the owner
    /// @param shares_ The amount of shares that is removed
    event SharesRemoved(address indexed owner_, uint256 shares_);

    /// @notice Emitted when the pool cover is liquidated
    /// @param toPool_ The amount of funds that is sent to the pool
    event CoverLiquidated(uint256 toPool_);
}

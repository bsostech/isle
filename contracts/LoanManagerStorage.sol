// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { ILoanManagerStorage } from "./interfaces/ILoanManagerStorage.sol";

abstract contract LoanManagerStorage is ILoanManagerStorage {
    /*//////////////////////////////////////////////////////////////////////////
                                    STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    enum LoanStatus {
        PENDING,
        ACTIVE,
        IMPAIRED,
        DEFAULTED
    }

    struct LoanInfo {
        LoanStatus status;
        bool withdrawn;
        address buyer;
        address seller;
        uint256 collateralTokenId;
        uint256 principal;
        uint256 interestRate;
        uint256 lateInterestPremiumRate;
        uint256 fee;
        uint256 startDate;
        uint256 dueDate;
        uint256 originalDueDate;
        uint256 gracePeriod;
    }

    struct LiquidationInfo {
        bool triggeredByGovernor;
        uint128 principal;
        uint120 interest;
        uint256 lateInterest;
        uint96 protocolFees;
    }

    struct PaymentInfo {
        uint24 protocolFeeRate;
        uint24 adminFeeRate;
        uint48 startDate;
        uint48 dueDate;
        uint128 incomingNetInterest;
        uint256 issuanceRate;
    }

    struct SortedPayment {
        uint24 previous;
        uint24 next;
        uint48 paymentDueDate;
    }

    struct Impairment {
        uint40 impairedDate; // Slot1: uint40 - Until year 36,812
        bool impariedByGovernor;
    }

    uint16 public loanCounter;
    uint24 public paymentCounter;
    uint24 public paymentWithEarliestDueDate;
    uint48 public domainStart;
    uint48 public domainEnd;
    uint112 public accountedInterest;
    uint128 public principalOut;
    uint128 public override unrealizedLosses;
    uint256 public issuanceRate;

    // Addresses below to preserve full storage slots
    address public fundsAsset;
    address public collateralAsset;

    mapping(uint16 => Impairment) public impairmentFor;
    mapping(uint256 => PaymentInfo) public payments;
    mapping(uint256 => SortedPayment) public sortedPayments;
    mapping(uint16 => LiquidationInfo) public liquidationInfoFor;
    mapping(uint16 => uint24) public paymentIdOf;

    mapping(uint16 => LoanInfo) internal _loans;
}

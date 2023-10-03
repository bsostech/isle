// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { LoanManager_Integration_Shared_Test } from "./LoanManager.t.sol";

abstract contract Callable_Integration_Shared_Test is LoanManager_Integration_Shared_Test {
    function setUp() public virtual override {
        changePrank(users.poolAdmin);
    }

    modifier WhenNotPaused() {
        _;
    }

    modifier WhenCallerPoolAdminOrGovernor() {
        changePrank(users.poolAdmin);
        _;
    }

    modifier WhenCallerPoolAdmin() {
        changePrank(users.poolAdmin);
        _;
    }
}

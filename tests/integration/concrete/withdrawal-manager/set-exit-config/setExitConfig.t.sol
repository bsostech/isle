// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { WithdrawalManager } from "contracts/libraries/types/DataTypes.sol";

import { WithdrawalManager_Integration_Shared_Test } from "../../../shared/withdrawal-manager/WithdrawalManager.t.sol";

contract setExitConfig_Integration_Concrete_Test is WithdrawalManager_Integration_Shared_Test {
    modifier whenProtocolNotPaused() {
        _;
    }

    modifier whenNewWindowlNotZero() {
        _;
    }

    modifier whenNewWindowlNotGreaterThanNewCycle() {
        _;
    }

    function setUp() public virtual override(WithdrawalManager_Integration_Shared_Test) {
        WithdrawalManager_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_ProtocolPaused() external {
        changePrank(users.governor);
        isleGlobals.setProtocolPaused(true);
        vm.expectRevert(abi.encodeWithSelector(Errors.ProtocolPaused.selector));
        setDefaultNewExitConfig();
    }

    function test_RevertWhen_NotPoolAdmin() external whenProtocolNotPaused {
        changePrank(users.caller);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotPoolAdmin.selector, users.caller));
        setDefaultNewExitConfig();
    }

    function test_RevertWhen_ZeroWindow() external whenProtocolNotPaused whenCallerPoolAdmin {
        uint256 newCycleDuration_ = defaults.NEW_CYCLE_DURATION();

        vm.expectRevert(abi.encodeWithSelector(Errors.WithdrawalManager_ZeroWindow.selector));
        withdrawalManager.setExitConfig({ cycleDuration_: newCycleDuration_, windowDuration_: 0 });
    }

    function test_RevertWhen_WindowGreaterThanCycle()
        external
        whenProtocolNotPaused
        whenCallerPoolAdmin
        whenNewWindowlNotZero
    {
        uint256 newCycleDuration_ = defaults.NEW_CYCLE_DURATION();
        uint256 newWindowDuration_ = defaults.NEW_WINDOW_DURATION() + 15 days;

        vm.expectRevert(abi.encodeWithSelector(Errors.WithdrawalManager_WindowGreaterThanCycle.selector));
        withdrawalManager.setExitConfig({ cycleDuration_: newCycleDuration_, windowDuration_: newWindowDuration_ });
    }

    function test_setExitConfig()
        public
        whenProtocolNotPaused
        whenCallerPoolAdmin
        whenNewWindowlNotZero
        whenNewWindowlNotGreaterThanNewCycle
    {
        WithdrawalManager.CycleConfig memory expectedLatestConfig_ = WithdrawalManager.CycleConfig({
            initialCycleId: 4,
            initialCycleTime: defaults.WINDOW_4(),
            windowDuration: defaults.NEW_WINDOW_DURATION(),
            cycleDuration: defaults.NEW_CYCLE_DURATION()
        });

        vm.expectEmit(address(withdrawalManager));
        emit ConfigurationUpdated({
            configId_: withdrawalManager.latestConfigId() + 1,
            initialCycleId_: expectedLatestConfig_.initialCycleId,
            initialCycleTime_: expectedLatestConfig_.initialCycleTime,
            cycleDuration_: expectedLatestConfig_.cycleDuration,
            windowDuration_: expectedLatestConfig_.windowDuration
        });
        setDefaultNewExitConfig();

        WithdrawalManager.CycleConfig memory actualLatestConfig_ =
            withdrawalManager.getCycleConfig(withdrawalManager.latestConfigId());

        assertEq(expectedLatestConfig_, actualLatestConfig_);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Pool } from "../contracts/Pool.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";
import { MockPoolConfigurator, MockERC20Pool } from "./mocks/Mocks.sol";
import { TestUtils } from "./utils/TestUtils.sol";
import { ERC20User } from "./accounts/ERC20User.sol";
import { IERC20Errors } from "../contracts/vendor/interfaces/IERC20Errors.sol";
import { IERC20 } from "../contracts/interfaces/IERC20.sol";

import { console2 } from "@forge-std/console2.sol";

contract ERC20BaseTest is TestUtils, IERC20Errors {

    address internal immutable self = address(this);

    MockERC20 internal _token;

    function setUp() public virtual {
        _token = new MockERC20("Token", "TKN");
    }

    function invariant_metadata() public {
        assertEq(_token.name(),     "Token");
        assertEq(_token.symbol(),   "TKN");
        assertEq(_token.decimals(), 18);
    }

    function testFuzz_metadata(string memory name_, string memory symbol_) public {
        MockERC20 mockToken = new MockERC20(name_, symbol_);

        assertEq(mockToken.name(),     name_);
        assertEq(mockToken.symbol(),   symbol_);
        assertEq(mockToken.decimals(), 18);
    }

    function testFuzz_mint(address account_, uint256 amount_) public {
        vm.assume(account_ != address(0));

        _token.mint(account_, amount_);

        assertEq(_token.totalSupply(),       amount_);
        assertEq(_token.balanceOf(account_), amount_);
    }

    function testFuzz_burn(address account_, uint256 amount0_, uint256 amount1_) public {
        vm.assume(account_ != address(0));

        if (amount1_ > amount0_) return;  // Mint amount must exceed burn amount.

        _token.mint(account_, amount0_);
        _token.burn(account_, amount1_);

        assertEq(_token.totalSupply(),       amount0_ - amount1_);
        assertEq(_token.balanceOf(account_), amount0_ - amount1_);
    }

    function testFuzz_approve(address account_, uint256 amount_) public {
        vm.assume(account_ != address(0));

        assertTrue(_token.approve(account_, amount_));

        assertEq(_token.allowance(self, account_), amount_);
    }


    function testFuzz_increaseAllowance(address account_, uint256 initialAmount_, uint256 addedAmount_) public {
        vm.assume(account_ != address(0) && initialAmount_ < type(uint256).max / 2 && addedAmount_ < type(uint256).max / 2);

        _token.approve(account_, initialAmount_);

        assertEq(_token.allowance(self, account_), initialAmount_);

        assertTrue(_token.increaseAllowance(account_, addedAmount_));

        assertEq(_token.allowance(self, account_), initialAmount_ + addedAmount_);
    }

    function testFuzz_decreaseAllowance_infiniteApproval(address account_, uint256 subtractedAmount_) public {
        uint256 MAX_UINT256 = type(uint256).max;

        vm.assume(account_ != address(0));
        vm.assume(subtractedAmount_ < MAX_UINT256);

        _token.approve(account_, MAX_UINT256);

        assertEq(_token.allowance(self, account_), MAX_UINT256);

        assertTrue(_token.decreaseAllowance(account_, subtractedAmount_));

        assertEq(_token.allowance(self, account_), MAX_UINT256);
    }


    function testFuzz_decreaseAllowance_nonInfiniteApproval(address account_, uint256 initialAmount_, uint256 subtractedAmount_) public {
        vm.assume(account_ != address(0));
        vm.assume(initialAmount_ < type(uint256).max);
        vm.assume(subtractedAmount_ <= initialAmount_);

        _token.approve(account_, initialAmount_);

        assertEq(_token.allowance(self, account_), initialAmount_);

        assertTrue(_token.decreaseAllowance(account_, subtractedAmount_));

        assertEq(_token.allowance(self, account_), initialAmount_ - subtractedAmount_);
    }

    function testFuzz_transfer(address account_, uint256 amount_) public {
        vm.assume(account_ != address(0));

        _token.mint(self, amount_);

        assertTrue(_token.transfer(account_, amount_));

        assertEq(_token.totalSupply(), amount_);

        if (self == account_) {
            assertEq(_token.balanceOf(self), amount_);
        } else {
            assertEq(_token.balanceOf(self),     0);
            assertEq(_token.balanceOf(account_), amount_);
        }
    }

    function testFuzz_transferFrom(address recipient_, uint256 approval_, uint256 amount_) public {
        vm.assume(recipient_ != address(0));
        vm.assume(approval_ < type(uint256).max);
        vm.assume(amount_ <= approval_);

        ERC20User owner = new ERC20User();

        _token.mint(address(owner), amount_);
        owner.erc20_approve(address(_token), self, approval_);

        assertTrue(_token.transferFrom(address(owner), recipient_, amount_));

        assertEq(_token.totalSupply(), amount_);

        approval_ = address(owner) == self ? approval_ : approval_ - amount_;

        assertEq(_token.allowance(address(owner), self), approval_);

        if (address(owner) == recipient_) {
            assertEq(_token.balanceOf(address(owner)), amount_);
        } else {
            assertEq(_token.balanceOf(address(owner)), 0);
            assertEq(_token.balanceOf(recipient_), amount_);
        }
    }

    function testFuzz_transferFrom_infiniteApproval(address recipient_, uint256 amount_) public {
        uint256 MAX_UINT256 = type(uint256).max;

        vm.assume(recipient_ != address(0));

        ERC20User owner = new ERC20User();

        _token.mint(address(owner), amount_);
        owner.erc20_approve(address(_token), self, MAX_UINT256);

        assertEq(_token.balanceOf(address(owner)),       amount_);
        assertEq(_token.totalSupply(),                   amount_);
        assertEq(_token.allowance(address(owner), self), MAX_UINT256);

        assertTrue(_token.transferFrom(address(owner), recipient_, amount_));

        assertEq(_token.totalSupply(),                   amount_);
        assertEq(_token.allowance(address(owner), self), MAX_UINT256);

        if (address(owner) == recipient_) {
            assertEq(_token.balanceOf(address(owner)), amount_);
        } else {
            assertEq(_token.balanceOf(address(owner)), 0);
            assertEq(_token.balanceOf(recipient_),     amount_);
        }
    }

    function testFuzz_transfer_insufficientBalance(address recipient_, uint256 amount_) public {
        vm.assume(recipient_ != address(0) && amount_ > 0);

        ERC20User account = new ERC20User();

        _token.mint(address(account), amount_ - 1);

        vm.expectRevert(
            abi.encodeWithSelector(ERC20InsufficientBalance.selector, address(account), amount_ - 1, amount_)
        );
        account.erc20_transfer(address(_token), recipient_, amount_);

        _token.mint(address(account), 1);
        account.erc20_transfer(address(_token), recipient_, amount_);

        assertEq(_token.balanceOf(recipient_), amount_);
    }

    function testFuzz_transferFrom_insufficientAllowance(address recipient_, uint256 amount_) public {

        vm.assume(recipient_ != address(0) && amount_ > 0);

        ERC20User owner = new ERC20User();

        _token.mint(address(owner), amount_);

        owner.erc20_approve(address(_token), self, amount_ - 1);

        vm.expectRevert(
            abi.encodeWithSelector(ERC20InsufficientAllowance.selector, self, amount_ - 1, amount_)
        );

        _token.transferFrom(address(owner), recipient_, amount_);

        owner.erc20_approve(address(_token), self, amount_);
        _token.transferFrom(address(owner), recipient_, amount_);

        assertEq(_token.balanceOf(recipient_), amount_);
    }

    function testFuzz_transferFrom_insufficientBalance(address recipient_, uint256 amount_) public {
        vm.assume(recipient_ != address(0) && amount_ > 0);

        ERC20User owner = new ERC20User();

        _token.mint(address(owner), amount_ - 1);
        owner.erc20_approve(address(_token), self, amount_);

        vm.expectRevert(
            abi.encodeWithSelector(ERC20InsufficientBalance.selector, address(owner), amount_ - 1, amount_)
        );

        _token.transferFrom(address(owner), recipient_, amount_);

        _token.mint(address(owner), 1);
        _token.transferFrom(address(owner), recipient_, amount_);

        assertEq(_token.balanceOf(recipient_), amount_);
    }
}

contract ERC20PermitTest is TestUtils, IERC20Errors {

    bytes internal constant ARITHMETIC_ERROR = abi.encodeWithSignature("Panic(uint256)", 0x11);

    uint256 internal constant S_VALUE_INCLUSIVE_UPPER_BOUND = uint256(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0);
    uint256 internal constant WAD = 10 ** 18;

    address internal _owner;
    address internal _spender;

    uint256 internal _skOwner   = 1;
    uint256 internal _skSpender = 2;
    uint256 internal _nonce     = 0;
    uint256 internal _deadline  = 5_000_000_000;  // Timestamp far in the future

    MockERC20 internal _token;
    ERC20User internal _user;

    function setUp() public virtual {
        _owner   = vm.addr(_skOwner);
        _spender = vm.addr(_skSpender);

        vm.warp(_deadline - 52 weeks);

        _token = new MockERC20("Token", "TKN");
        _user  = new ERC20User();
    }

    function test_typehash() external {
        assertEq(_token.PERMIT_TYPEHASH(), keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"));
    }

    // NOTE: Virtual so inheriting tests can override with different DOMAIN_SEPARATORs because of different addresses
    function test_domainSeparator() public virtual {
        // console2.log("Name: ", _token.name());
        // console2.log("Address: ", address(_token));

        assertEq(_token.DOMAIN_SEPARATOR(), 0xaa9e832a9ef68cda525e9c935a73b5f1f4a30877cfb71ae89cf97bb686658b2c);
    }


    function test_initialState() public {
        assertEq(_token.nonces(_owner),              0);
        assertEq(_token.allowance(_owner, _spender), 0);
    }

    function testFuzz_permit(uint256 amount_) public {
        uint256 startingNonce = _token.nonces(_owner);
        uint256 expectedNonce = startingNonce + 1;

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) = _getValidPermitSignature(address(_token), _owner, _spender, amount_, startingNonce, _deadline, _skOwner);

        _user.erc20_permit(address(_token), _owner, _spender, amount_, _deadline, v, r, s);

        assertEq(_token.nonces(_owner),              expectedNonce);
        assertEq(_token.allowance(_owner, _spender), amount_);
    }

    function testFuzz_permit_multiple(bytes32 seed_) public {
        for (uint256 i; i < 10; ++i) {
            testFuzz_permit(uint256(keccak256(abi.encodePacked(seed_, i))));
        }
    }

    function test_permit_zeroAddress() public {
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(address(_token), _owner, _spender, 1000, 0, _deadline, _skOwner);
        vm.expectRevert();
        _user.erc20_permit(address(_token), address(0), _spender, 1000, _deadline, v, r, s);
    }

    function test_permit_differentSpender() public {
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(address(_token), _owner, address(1111), 1000, 0, _deadline, _skOwner);

        // Using permit with unintended spender should fail.
        vm.expectRevert();

        _user.erc20_permit(address(_token), _owner, _spender, 1000, _deadline, v, r, s);
    }

    function test_permit_ownerSignerMismatch() public {
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(address(_token), _owner, _spender, 1000, 0, _deadline, _skSpender);

        vm.expectRevert();

        _user.erc20_permit(address(_token), _owner, _spender, 1000, _deadline, v, r, s);
    }

    function test_permit_withExpiry() public {
        uint256 expiry = 482112000 + 1 hours;

        // Expired permit should fail
        vm.warp(482112000 + 1 hours + 1);

        assertEq(block.timestamp, 482112000 + 1 hours + 1);

        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(address(_token), _owner, _spender, 1000, 0, expiry, _skOwner);

        vm.expectRevert(abi.encodeWithSelector(ERC2612ExpiredSignature.selector, expiry));

        _user.erc20_permit(address(_token), _owner, _spender, 1000, expiry, v, r, s);

        assertEq(_token.allowance(_owner, _spender), 0);
        assertEq(_token.nonces(_owner),              0);

        // Valid permit should succeed
        vm.warp(482112000 + 1 hours);

        assertEq(block.timestamp, 482112000 + 1 hours);

        ( v, r, s ) = _getValidPermitSignature(address(_token), _owner, _spender, 1000, 0, expiry, _skOwner);

        _user.erc20_permit(address(_token), _owner, _spender, 1000, expiry, v, r, s);

        assertEq(_token.allowance(_owner, _spender), 1000);
        assertEq(_token.nonces(_owner),              1);
    }

    function test_permit_replay() public {
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(address(_token), _owner, _spender, 1000, 0, _deadline, _skOwner);

        // First time should succeed
        _user.erc20_permit(address(_token), _owner, _spender, 1000, _deadline, v, r, s);

        // Second time nonce has been consumed and should fail
        vm.expectRevert();

        _user.erc20_permit(address(_token), _owner, _spender, 1000, _deadline, v, r, s);
    }

    function test_permit_earlyNonce() public {
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(address(_token), _owner, _spender, 1000, 1, _deadline, _skOwner);

        // Previous nonce of 0 has not been consumed yet, so nonce of 1 should fail.
        vm.expectRevert();

        _user.erc20_permit(address(_token), _owner, _spender, 1000, _deadline, v, r, s);
    }

    function test_permit_differentVerifier() public {
        address someToken = address(new MockERC20("Some Token", "ST"));

        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(someToken, _owner, _spender, 1000, 0, _deadline, _skOwner);

        // Using permit with unintended verifier should fail.
        vm.expectRevert();

        _user.erc20_permit(address(_token), _owner, _spender, 1000, _deadline, v, r, s);
    }

    function test_permit_badS() public {
        ( uint8 v, bytes32 r, ) = _getValidPermitSignature(address(_token), _owner, _spender, 1000, 0, _deadline, _skOwner);

        // Send in an s that is above the upper bound.
        bytes32 badS = bytes32(S_VALUE_INCLUSIVE_UPPER_BOUND + 1);
        vm.expectRevert("ERC20:P:MALLEABLE");
        _user.erc20_permit(address(_token), _owner, _spender, 1000, _deadline, v, r, badS);
    }

    function test_permit_badV() public {
        // Get valid signature. The `v` value is the expected v value that will cause `permit` to succeed, and must be 27 or 28.
        // Any other value should fail.
        // If v is 27, then 28 should make it past the MALLEABLE require, but should result in an invalid signature,
        // and vice versa when v is 28.
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(address(_token), _owner, _spender, 1000, 0, _deadline, _skOwner);

        for (uint8 i; i <= type(uint8).max; i++) {
            if (i == type(uint8).max) {
                break;
            } else if (i != 27 && i != 28) {
                vm.expectRevert("ERC20:P:MALLEABLE");
            } else {
                if (i == v) continue;

                // Should get past the Malleable require check as 27 or 28 are valid values for s.
                vm.expectRevert();
            }

            _user.erc20_permit(address(_token), _owner, _spender, 1000, _deadline, i, r, s);
        }
    }

    // Returns an ERC-2612 `permit` digest for the `owner` to sign
    function _getDigest(address token_, address owner_, address spender_, uint256 amount_, uint256 nonce_, uint256 deadline_)
        internal view returns (bytes32 digest_)
    {
        return keccak256(
            abi.encodePacked(
                '\x19\x01',
                IERC20(token_).DOMAIN_SEPARATOR(),
                keccak256(abi.encode(IERC20(token_).PERMIT_TYPEHASH(), owner_, spender_, amount_, nonce_, deadline_))
            )
        );
    }

    // Returns a valid `permit` signature signed by this contract's `owner` address
    function _getValidPermitSignature(
        address token_,
        address owner_,
        address spender_,
        uint256 amount_,
        uint256 nonce_,
        uint256 deadline_,
        uint256 ownerSk_
    )
        internal view returns (uint8 v_, bytes32 r_, bytes32 s_)
    {
        return vm.sign(ownerSk_, _getDigest(token_, owner_, spender_, amount_, nonce_, deadline_));
    }

}


contract Pool_ERC20TestBase {

    address internal pool;

    MockERC20 internal asset;

    function _setupPoolWithERC20() internal {
        asset = new MockERC20("Asset", "AT");
        MockPoolConfigurator poolConfigurator = new MockPoolConfigurator();

        pool = address(new MockERC20Pool(address(poolConfigurator), address(asset), "Token", "TKN"));
    }
}

contract Pool_ERC20Test is ERC20BaseTest, Pool_ERC20TestBase {
    function setUp() override public {
        super.setUp();
        _setupPoolWithERC20();
        _token = MockERC20(pool);
    }
}

contract Pool_ERC20PermitTest is ERC20PermitTest, Pool_ERC20TestBase {
    function setUp() override public {
        super.setUp();
        _setupPoolWithERC20();
        _token = MockERC20(pool);
    }

    function test_domainSeparator() public override {
        assertEq(_token.DOMAIN_SEPARATOR(), 0x26450e8015bd7b9fa21048f5ff3a98f55954aa7364a274646e99f55efbfe5c69);
    }
}


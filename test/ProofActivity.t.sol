// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ProofActivity.sol";
import "./mocks/MockERC20.sol";

contract SPAMDistributorTest is Test {
    SPAMDistributor public distributor;
    MockERC20 public mockToken;

    // Actors
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    
    // Constants
    uint256 public constant EPOCH_DURATION = 1 days; // 1 day in seconds
    uint256 public constant TOTAL_EPOCH_REWARD = 10_000_000_000_000; // 10 trillion tokens

    function setUp() public {
        // Setup with owner as a specific address
        vm.startPrank(owner);
        
        // Deploy the mock token with 4 decimals
        mockToken = new MockERC20("Mock Token", "MTK", 4);
        
        // Deploy the distributor contract
        distributor = new SPAMDistributor(address(mockToken));
        
        // Mint tokens to owner and approve for distributor
        uint256 initialSupply = 10_000_000_000_000 * 10 ** 4; // 10 trillion with 4 decimals
        mockToken.mint(owner, initialSupply);
        mockToken.approve(address(distributor), initialSupply);
        
        // Deposit tokens to the distributor
        distributor.depositTokens(initialSupply);
        
        // Resume the distributor (unpause)
        distributor.resume();
        
        vm.stopPrank();
    }

    // ====== Deployment Tests ======

    function testDeployment() public view {
        assertEq(address(distributor.rewardToken()), address(mockToken));
        assertEq(distributor.owner(), owner);
    }

    function testInitiallyPaused() public {
        // Deploy a new instance without resuming
        vm.startPrank(owner);
        SPAMDistributor newDistributor = new SPAMDistributor(address(mockToken));
        vm.stopPrank();
        
        assertTrue(newDistributor.paused());
    }

    function testTokenDeposit() public view {
        uint256 balance = mockToken.balanceOf(address(distributor));
        assertTrue(balance > 0);
    }

    // ====== User Counter Creation Tests ======

    function testCreateUserCounter() public {
        vm.prank(user1);
        distributor.newUserCounter();
        
        (uint256 txCount, bool registered, bool claimed) = distributor.getUserCounterInfo(user1, 0);
        assertEq(txCount, 1);
        assertEq(registered, false);
        assertEq(claimed, false);
    }

    function testIncrementUserCounter() public {
        vm.startPrank(user1);
        distributor.newUserCounter();
        distributor.incrementUserCounter();
        vm.stopPrank();
        
        (uint256 txCount, , ) = distributor.getUserCounterInfo(user1, 0);
        assertEq(txCount, 2);
    }

    function test_RevertWhen_IncrementWithoutInit() public {
        vm.prank(user1);
        vm.expectRevert("Counter not initialized");
        distributor.incrementUserCounter();
    }

    function test_RevertWhen_ContractIsPaused() public {
        vm.prank(owner);
        distributor.pause();
        
        vm.prank(user1);
        vm.expectRevert("Director is paused");
        distributor.newUserCounter();
    }

    // ====== User Counter Registration Tests ======

    function testRegisterUserCounter() public {
        // Create counter in epoch 0
        vm.prank(user1);
        distributor.newUserCounter();
        
        // Move to epoch 1
        vm.warp(block.timestamp + EPOCH_DURATION);
        
        // Register counter from epoch 0
        vm.prank(user1);
        distributor.registerUserCounter();
        
        // Check if counter is registered
        (, bool registered, ) = distributor.getUserCounterInfo(user1, 0);
        assertTrue(registered);
    }

    function test_RevertWhen_RegisterInSameEpoch() public {
        // Create counter in epoch 0
        vm.prank(user1);
        distributor.newUserCounter();
        
        // Try to register in the same epoch
        vm.prank(user1);
        vm.expectRevert();
        distributor.registerUserCounter();
    }

    function test_RevertWhen_RegisterTwice() public {
        // Create counter in epoch 0
        vm.prank(user1);
        distributor.newUserCounter();
        
        // Move to epoch 1
        vm.warp(block.timestamp + EPOCH_DURATION);
        
        // Register counter from epoch 0
        vm.prank(user1);
        distributor.registerUserCounter();
        
        // Try to register again
        vm.prank(user1);
        vm.expectRevert("Counter already registered");
        distributor.registerUserCounter();
    }

    // ====== Reward Claiming Tests ======

    function testClaimRewards() public {
        // Create counter in epoch 0
        vm.prank(user1);
        distributor.newUserCounter();
        
        // Move to epoch 1
        vm.warp(block.timestamp + EPOCH_DURATION);
        
        // Register counter from epoch 0
        vm.prank(user1);
        distributor.registerUserCounter();
        
        // Move to epoch 2
        vm.warp(block.timestamp + EPOCH_DURATION);
        
        // Check balance before claiming
        uint256 balanceBefore = mockToken.balanceOf(user1);
        
        // Claim rewards
        vm.prank(user1);
        distributor.claimUserReward(0);
        
        // Check balance after claiming
        uint256 balanceAfter = mockToken.balanceOf(user1);
        
        // Should have received tokens
        assertTrue(balanceAfter > balanceBefore);
        
        // Counter should be marked as claimed
        (, , bool claimed) = distributor.getUserCounterInfo(user1, 0);
        assertTrue(claimed);
    }

    function test_RevertWhen_ClaimTooEarly() public {
        // Create counter in epoch 0
        vm.prank(user1);
        distributor.newUserCounter();
        
        // Move to epoch 1
        vm.warp(block.timestamp + EPOCH_DURATION);
        
        // Register counter from epoch 0
        vm.prank(user1);
        distributor.registerUserCounter();
        
        // Try to claim immediately (should fail)
        vm.prank(user1);
        // Chỉ mong đợi có lỗi nhưng không chỉ định cụ thể thông báo lỗi
        vm.expectRevert();
        distributor.claimUserReward(0);
    }

    function test_RevertWhen_ClaimWithoutRegistering() public {
        vm.prank(user1);
        distributor.newUserCounter();
        
        // Move to epoch 2
        vm.warp(block.timestamp + EPOCH_DURATION * 2);
        
        // Try to claim without registering
        vm.prank(user1);
        vm.expectRevert("Counter not registered");
        distributor.claimUserReward(0);
    }

    function test_RevertWhen_ClaimTwice() public {
        // Create counter in epoch 0
        vm.prank(user1);
        distributor.newUserCounter();
        
        // Move to epoch 1
        vm.warp(block.timestamp + EPOCH_DURATION);
        
        // Register counter from epoch 0
        vm.prank(user1);
        distributor.registerUserCounter();
        
        // Move to epoch 2
        vm.warp(block.timestamp + EPOCH_DURATION);
        
        // Claim rewards
        vm.prank(user1);
        distributor.claimUserReward(0);
        
        // Try to claim again
        vm.prank(user1);
        vm.expectRevert("Rewards already claimed");
        distributor.claimUserReward(0);
    }

    function testProportionalRewards() public {
        // User1 creates counter in epoch 0 with 3 txs
        vm.startPrank(user1);
        distributor.newUserCounter();
        distributor.incrementUserCounter();
        distributor.incrementUserCounter();
        vm.stopPrank();
        
        // User2 creates counter in epoch 0 with 1 tx
        vm.prank(user2);
        distributor.newUserCounter();
        
        // Move to epoch 1
        vm.warp(block.timestamp + EPOCH_DURATION);
        
        // Register both counters
        vm.prank(user1);
        distributor.registerUserCounter();
        
        vm.prank(user2);
        distributor.registerUserCounter();
        
        // Move to epoch 2
        vm.warp(block.timestamp + EPOCH_DURATION);
        
        // Get balances before claiming
        uint256 user1BalanceBefore = mockToken.balanceOf(user1);
        uint256 user2BalanceBefore = mockToken.balanceOf(user2);
        
        // Claim rewards
        vm.prank(user1);
        distributor.claimUserReward(0);
        
        vm.prank(user2);
        distributor.claimUserReward(0);
        
        // Get balances after claiming
        uint256 user1Reward = mockToken.balanceOf(user1) - user1BalanceBefore;
        uint256 user2Reward = mockToken.balanceOf(user2) - user2BalanceBefore;
        
        // User1 should get 3/4 of rewards, User2 should get 1/4
        // Total txs = 4, User1 = 3 txs, User2 = 1 tx
        assertEq(user1Reward, user2Reward * 3);
    }

    // ====== Admin Functions Tests ======

    function testPauseAndResume() public {
        vm.startPrank(owner);
        distributor.pause();
        assertTrue(distributor.paused());
        
        distributor.resume();
        assertFalse(distributor.paused());
        vm.stopPrank();
    }

    function test_RevertWhen_NonOwnerPause() public {
        vm.prank(user1);
        vm.expectRevert("Not owner");
        distributor.pause();
    }

    function testTransferOwnership() public {
        vm.prank(owner);
        distributor.transferOwnership(user1);
        
        assertEq(distributor.owner(), user1);
        
        // New owner should be able to pause
        vm.prank(user1);
        distributor.pause();
        assertTrue(distributor.paused());
    }

    function testRecoverWrongTokens() public {
        // Deploy another token
        MockERC20 otherToken = new MockERC20("Other Token", "OTK", 18);
        
        // Mint some tokens and send to the distributor
        uint256 amount = 100 * 10 ** 18;
        otherToken.mint(address(distributor), amount);
        
        // Recover tokens
        vm.prank(owner);
        distributor.recoverERC20(address(otherToken), amount);
        
        // Owner should have received the tokens
        assertEq(otherToken.balanceOf(owner), amount);
    }

    function test_RevertWhen_RecoverRewardToken() public {
        vm.prank(owner);
        vm.expectRevert("Cannot recover reward tokens");
        distributor.recoverERC20(address(mockToken), 1);
    }

    // ====== View Functions Tests ======

    function testCurrentEpoch() public {
        assertEq(distributor.getCurrentEpoch(), 0);
        
        vm.warp(block.timestamp + EPOCH_DURATION);
        assertEq(distributor.getCurrentEpoch(), 1);
        
        vm.warp(block.timestamp + EPOCH_DURATION);
        assertEq(distributor.getCurrentEpoch(), 2);
    }

    function testEpochTimeRemaining() public view {
        uint256 remaining = distributor.getEpochTimeRemaining();
        assertTrue(remaining <= EPOCH_DURATION);
        assertTrue(remaining > 0);
    }

    function testGetStatsForRecentEpochs() public {
        // Create and register counters across 3 epochs
        
        // Epoch 0
        vm.prank(user1);
        distributor.newUserCounter();
        
        // Epoch 1
        vm.warp(block.timestamp + EPOCH_DURATION);
        vm.prank(user1);
        distributor.registerUserCounter();
        
        vm.prank(user2);
        distributor.newUserCounter();
        
        // Epoch 2
        vm.warp(block.timestamp + EPOCH_DURATION);
        vm.prank(user2);
        distributor.registerUserCounter();
        
        // Get stats for 2 recent epochs
        uint256[] memory epochNumbers = new uint256[](2);
        epochNumbers[0] = 1;
        epochNumbers[1] = 0;
        
        SPAMDistributor.Stats memory stats = distributor.getStatsForEpochs(epochNumbers);
        
        assertEq(stats.currentEpoch, 2);
        assertEq(stats.epochs.length, 2);
        assertEq(stats.epochs[0].epoch, 1);
        assertEq(stats.epochs[1].epoch, 0);
        
        // Epoch 0 had 1 tx from user1
        assertEq(stats.epochs[1].txCount, 1);
        
        // Epoch 1 had 1 tx from user2
        assertEq(stats.epochs[0].txCount, 1);
    }
}
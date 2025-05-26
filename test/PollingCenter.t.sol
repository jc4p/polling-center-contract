// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {PollingCenter} from "../src/PollingCenter.sol";

contract PollingCenterTest is Test {
    PollingCenter public pollingCenter;
    
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    
    uint256 public constant USER1_FID = 12345;
    uint256 public constant USER2_FID = 67890;
    uint256 public constant CREATOR_FID = 11111;
    
    string public constant POLL_ID_1 = "poll_1234567890_abcdef123";
    string public constant POLL_ID_2 = "poll_2345678901_bcdefg456";

    function setUp() public {
        vm.prank(owner);
        pollingCenter = new PollingCenter();
    }

    function test_OwnerIsSetCorrectly() public view {
        assertEq(pollingCenter.owner(), owner);
    }

    function test_CreatePoll_Success() public {
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);

        PollingCenter.Poll memory poll = pollingCenter.getPoll(POLL_ID_1);
        
        assertEq(poll.pollId, POLL_ID_1);
        assertEq(poll.creator, user1);
        assertEq(poll.creatorFid, CREATOR_FID);
        assertEq(poll.optionCount, 3);
        assertTrue(poll.active);
        assertEq(poll.expiresAt, block.timestamp + 7 days);
    }

    function test_CreatePoll_EmitsPollCreatedEvent() public {
        vm.expectEmit(true, true, true, true);
        emit PollingCenter.PollCreated(POLL_ID_1, user1, CREATOR_FID, block.timestamp + 7 days);
        
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);
    }

    function test_CreatePoll_RevertWhenPollAlreadyExists() public {
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);

        vm.expectRevert(PollingCenter.PollAlreadyExists.selector);
        vm.prank(user2);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 5, 2);
    }

    function test_CreatePoll_RevertWhenInvalidDuration() public {
        vm.expectRevert(PollingCenter.InvalidDuration.selector);
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 0, 3);

        vm.expectRevert(PollingCenter.InvalidDuration.selector);
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_2, CREATOR_FID, 31, 3);
    }

    function test_CreatePoll_RevertWhenInvalidOptionCount() public {
        vm.expectRevert(PollingCenter.InvalidOptionCount.selector);
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 1);

        vm.expectRevert(PollingCenter.InvalidOptionCount.selector);
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_2, CREATOR_FID, 7, 11);
    }

    function test_SubmitVote_Success() public {
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);

        vm.prank(user2);
        pollingCenter.submitVote(POLL_ID_1, 1, USER2_FID);

        PollingCenter.Vote memory vote = pollingCenter.getVote(POLL_ID_1, 0);
        
        assertEq(vote.voterFid, USER2_FID);
        assertEq(vote.optionIndex, 1);
        assertEq(vote.timestamp, block.timestamp);
        
        assertTrue(pollingCenter.hasUserVoted(POLL_ID_1, USER2_FID));
        assertEq(pollingCenter.getTotalVotes(POLL_ID_1), 1);
    }

    function test_SubmitVote_EmitsVoteCastEvent() public {
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);

        vm.expectEmit(true, true, true, true);
        emit PollingCenter.VoteCast(POLL_ID_1, user2, USER2_FID, 1);
        
        vm.prank(user2);
        pollingCenter.submitVote(POLL_ID_1, 1, USER2_FID);
    }

    function test_SubmitVote_RevertWhenPollNotFound() public {
        vm.expectRevert(PollingCenter.PollNotFound.selector);
        vm.prank(user1);
        pollingCenter.submitVote("nonexistent_poll", 0, USER1_FID);
    }

    function test_SubmitVote_RevertWhenPollExpired() public {
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);

        vm.warp(block.timestamp + 8 days);

        vm.expectRevert(PollingCenter.PollExpired.selector);
        vm.prank(user2);
        pollingCenter.submitVote(POLL_ID_1, 1, USER2_FID);
    }

    function test_SubmitVote_RevertWhenInvalidOptionIndex() public {
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);

        vm.expectRevert(PollingCenter.InvalidOptionIndex.selector);
        vm.prank(user2);
        pollingCenter.submitVote(POLL_ID_1, 3, USER2_FID);
    }

    function test_SubmitVote_RevertWhenAlreadyVoted() public {
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);

        vm.prank(user2);
        pollingCenter.submitVote(POLL_ID_1, 1, USER2_FID);

        vm.expectRevert(PollingCenter.AlreadyVoted.selector);
        vm.prank(user2);
        pollingCenter.submitVote(POLL_ID_1, 2, USER2_FID);
    }

    function test_SubmitVote_RevertWhenPollInactive() public {
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);

        vm.prank(user1);
        pollingCenter.deactivatePoll(POLL_ID_1);

        vm.expectRevert(PollingCenter.PollInactive.selector);
        vm.prank(user2);
        pollingCenter.submitVote(POLL_ID_1, 1, USER2_FID);
    }

    function test_MultipleVotes() public {
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);

        vm.prank(user1);
        pollingCenter.submitVote(POLL_ID_1, 0, USER1_FID);

        vm.prank(user2);
        pollingCenter.submitVote(POLL_ID_1, 1, USER2_FID);

        assertEq(pollingCenter.getTotalVotes(POLL_ID_1), 2);
        assertTrue(pollingCenter.hasUserVoted(POLL_ID_1, USER1_FID));
        assertTrue(pollingCenter.hasUserVoted(POLL_ID_1, USER2_FID));

        PollingCenter.Vote memory vote1 = pollingCenter.getVote(POLL_ID_1, 0);
        PollingCenter.Vote memory vote2 = pollingCenter.getVote(POLL_ID_1, 1);

        assertEq(vote1.voterFid, USER1_FID);
        assertEq(vote1.optionIndex, 0);
        
        assertEq(vote2.voterFid, USER2_FID);
        assertEq(vote2.optionIndex, 1);
    }

    function test_DeactivatePoll_ByCreator() public {
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);

        assertTrue(pollingCenter.isPollActive(POLL_ID_1));

        vm.prank(user1);
        pollingCenter.deactivatePoll(POLL_ID_1);

        assertFalse(pollingCenter.isPollActive(POLL_ID_1));
    }

    function test_DeactivatePoll_ByOwner() public {
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);

        assertTrue(pollingCenter.isPollActive(POLL_ID_1));

        vm.prank(owner);
        pollingCenter.deactivatePoll(POLL_ID_1);

        assertFalse(pollingCenter.isPollActive(POLL_ID_1));
    }

    function test_DeactivatePoll_RevertWhenNotAuthorized() public {
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);

        vm.expectRevert("Not authorized");
        vm.prank(user2);
        pollingCenter.deactivatePoll(POLL_ID_1);
    }

    function test_DeactivatePoll_RevertWhenPollNotFound() public {
        vm.expectRevert(PollingCenter.PollNotFound.selector);
        vm.prank(user1);
        pollingCenter.deactivatePoll("nonexistent_poll");
    }

    function test_GetPoll_RevertWhenNotFound() public {
        vm.expectRevert(PollingCenter.PollNotFound.selector);
        pollingCenter.getPoll("nonexistent_poll");
    }

    function test_IsPollActive_ReturnsFalseWhenExpired() public {
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);

        assertTrue(pollingCenter.isPollActive(POLL_ID_1));

        vm.warp(block.timestamp + 8 days);

        assertFalse(pollingCenter.isPollActive(POLL_ID_1));
    }

    function test_GetVote_RevertWhenIndexOutOfBounds() public {
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);

        vm.expectRevert("Vote index out of bounds");
        pollingCenter.getVote(POLL_ID_1, 0);
    }

    function test_HasUserVoted_ReturnsFalseForNonVoter() public {
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);

        assertFalse(pollingCenter.hasUserVoted(POLL_ID_1, USER1_FID));
    }

    function test_GetTotalVotes_ReturnsZeroForNewPoll() public {
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);

        assertEq(pollingCenter.getTotalVotes(POLL_ID_1), 0);
    }

    function test_EdgeCase_VoteAtExactExpiryTime() public {
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);

        uint256 expiryTime = block.timestamp + 7 days;
        vm.warp(expiryTime);

        vm.expectRevert(PollingCenter.PollExpired.selector);
        vm.prank(user2);
        pollingCenter.submitVote(POLL_ID_1, 1, USER2_FID);
    }

    function test_EdgeCase_VoteJustBeforeExpiry() public {
        vm.prank(user1);
        pollingCenter.createPoll(POLL_ID_1, CREATOR_FID, 7, 3);

        uint256 expiryTime = block.timestamp + 7 days;
        vm.warp(expiryTime - 1);

        vm.prank(user2);
        pollingCenter.submitVote(POLL_ID_1, 1, USER2_FID);

        assertEq(pollingCenter.getTotalVotes(POLL_ID_1), 1);
    }
}
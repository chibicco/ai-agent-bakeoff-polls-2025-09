require "test_helper"

class VoteTest < ActiveSupport::TestCase
  setup do
    @poll = Poll.create!(title: "Test Poll", status: "open")
    @choice = @poll.choices.create!(label: "Option 1")
  end

  test "should create vote for open poll" do
    vote = Vote.new(poll: @poll, choice: @choice, voter_hash: "test_hash")
    assert vote.save
  end

  test "should not create vote for closed poll" do
    @poll.update!(status: "closed")
    vote = Vote.new(poll: @poll, choice: @choice, voter_hash: "test_hash")
    assert_not vote.save
    assert_includes vote.errors[:poll], "is not open for voting"
  end

  test "should not create vote for draft poll" do
    @poll.update!(status: "draft")
    vote = Vote.new(poll: @poll, choice: @choice, voter_hash: "test_hash")
    assert_not vote.save
  end

  test "should not allow duplicate votes with same voter_hash" do
    Vote.create!(poll: @poll, choice: @choice, voter_hash: "duplicate_hash")
    duplicate_vote = Vote.new(poll: @poll, choice: @choice, voter_hash: "duplicate_hash")
    assert_not duplicate_vote.save
    assert duplicate_vote.errors[:poll_id].any?
  end

  test "should allow votes with null voter_hash" do
    vote = Vote.new(poll: @poll, choice: @choice, voter_hash: nil)
    assert vote.save, "Should allow votes with null voter_hash"
  end

  test "should validate choice belongs to poll" do
    other_poll = Poll.create!(title: "Other Poll", status: "open")
    other_choice = other_poll.choices.create!(label: "Other Option")
    
    vote = Vote.new(poll: @poll, choice: other_choice, voter_hash: "test")
    assert_not vote.save
    assert_includes vote.errors[:choice], "does not belong to this poll"
  end

  test "should increment votes_count on create" do
    assert_difference "@choice.reload.votes_count", 1 do
      Vote.create!(poll: @poll, choice: @choice, voter_hash: "count_test")
    end
  end

  test "should decrement votes_count on destroy" do
    vote = Vote.create!(poll: @poll, choice: @choice, voter_hash: "destroy_test")
    assert_difference "@choice.reload.votes_count", -1 do
      vote.destroy
    end
  end
end
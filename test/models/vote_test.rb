require "test_helper"

class VoteTest < ActiveSupport::TestCase
  test "cannot save when choice does not belong to poll" do
    poll1 = Poll.create!(title: "p1", status: :open)
    poll2 = Poll.create!(title: "p2", status: :open)
    c1 = poll1.choices.create!(label: "A")
    vote = Vote.new(poll: poll2, choice: c1)
    assert_not vote.valid?
  end

  test "requires votable poll" do
    poll = Poll.create!(title: "closed", status: :closed)
    c = poll.choices.create!(label: "A")
    vote = Vote.new(poll: poll, choice: c)
    assert_not vote.valid?
  end

  test "voter_hash uniqueness scoped to poll" do
    poll = Poll.create!(title: "open", status: :open)
    c = poll.choices.create!(label: "A")
    vhash = "abc123"
    Vote.create!(poll: poll, choice: c, voter_hash: vhash)
    dup = Vote.new(poll: poll, choice: c, voter_hash: vhash)
    assert_not dup.valid?
  end

  test "counter_cache increments" do
    poll = Poll.create!(title: "open", status: :open)
    c = poll.choices.create!(label: "A")
    assert_difference -> { c.reload.votes_count } do
      Vote.create!(poll: poll, choice: c)
    end
  end
end


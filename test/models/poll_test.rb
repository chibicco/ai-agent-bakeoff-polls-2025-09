require "test_helper"

class PollTest < ActiveSupport::TestCase
  test "valid with title and slug auto-generated" do
    poll = Poll.new(title: "テスト", status: :draft)
    assert poll.valid?
    assert_difference -> { Poll.count } do
      poll.save!
    end
    assert_not_nil poll.slug
  end

  test "ended? is true when ends_at in past" do
    poll = Poll.create!(title: "締切", ends_at: 1.day.ago)
    assert poll.ended?
  end

  test "votable? requires open and not ended" do
    poll = Poll.create!(title: "公開", status: :open, ends_at: 1.day.from_now)
    assert poll.votable?
    poll.update!(ends_at: 1.hour.ago)
    assert_not poll.votable?
  end
end


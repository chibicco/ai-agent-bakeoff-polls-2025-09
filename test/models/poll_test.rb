require "test_helper"

class PollTest < ActiveSupport::TestCase
  test "should not save poll without title" do
    poll = Poll.new
    assert_not poll.save, "Saved the poll without a title"
  end

  test "should generate slug from title" do
    poll = Poll.new(title: "Test Poll")
    poll.valid?
    assert_not_nil poll.slug
  end

  test "should generate unique slug for duplicate titles" do
    poll1 = Poll.create!(title: "Same Title")
    poll2 = Poll.new(title: "Same Title")
    poll2.valid?
    assert_not_equal poll1.slug, poll2.slug
  end

  test "should generate slug for Japanese title" do
    poll = Poll.new(title: "日本語のタイトル")
    poll.valid?
    assert_match(/^poll-[a-f0-9]+$/, poll.slug)
  end

  test "should have draft status by default" do
    poll = Poll.new(title: "Test")
    assert_equal "draft", poll.status
  end

  test "should be open when status is open and no end date" do
    poll = Poll.new(title: "Test", status: "open", ends_at: nil)
    assert poll.open?
  end

  test "should be closed when past end date" do
    poll = Poll.new(title: "Test", status: "open", ends_at: 1.day.ago)
    assert poll.closed?
    assert_not poll.open?
  end

  test "should be closed when status is closed" do
    poll = Poll.new(title: "Test", status: "closed", ends_at: 1.day.from_now)
    assert poll.closed?
    assert_not poll.open?
  end
end
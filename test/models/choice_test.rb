require "test_helper"

class ChoiceTest < ActiveSupport::TestCase
  test "label presence" do
    poll = Poll.create!(title: "p")
    choice = poll.choices.build
    assert_not choice.valid?
    choice.label = "A"
    assert choice.valid?
  end
end


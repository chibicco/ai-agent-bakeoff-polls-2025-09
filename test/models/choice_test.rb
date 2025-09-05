require "test_helper"

class ChoiceTest < ActiveSupport::TestCase
  setup do
    @poll = Poll.create!(title: "Test Poll")
  end

  test "should not save choice without label" do
    choice = @poll.choices.build
    assert_not choice.save, "Saved the choice without a label"
  end

  test "should belong to poll" do
    choice = Choice.new(label: "Option")
    assert_not choice.save, "Saved choice without poll"
  end

  test "should have default votes_count of 0" do
    choice = @poll.choices.create!(label: "New Option")
    assert_equal 0, choice.votes_count
  end

  test "should be destroyed with poll" do
    choice = @poll.choices.create!(label: "Option")
    assert_difference "Choice.count", -1 do
      @poll.destroy
    end
  end
end
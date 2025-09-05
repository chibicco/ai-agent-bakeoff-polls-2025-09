require "test_helper"

class VotesControllerTest < ActionDispatch::IntegrationTest
  test "create vote and redirect to poll" do
    poll = Poll.create!(title: "open", status: :open)
    c = poll.choices.create!(label: "A")

    post poll_votes_path(poll), params: { choice_id: c.id }, headers: { "User-Agent" => "TestAgent" }
    assert_redirected_to poll_path(poll)
    follow_redirect!
    assert_match "投票ありがとうございました", @response.body
  end

  test "duplicate vote shows alert" do
    poll = Poll.create!(title: "open", status: :open)
    c = poll.choices.create!(label: "A")

    headers = { "User-Agent" => "SameUA" }
    2.times do
      post poll_votes_path(poll), params: { choice_id: c.id }, headers: headers
    end
    assert_redirected_to poll_path(poll)
  end
end


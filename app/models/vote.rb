class Vote < ApplicationRecord
  belongs_to :poll
  belongs_to :choice

  validates :poll_id, uniqueness: { scope: :voter_hash, allow_nil: true }
  validate :poll_must_be_open, on: :create
  validate :choice_belongs_to_poll

  after_create :increment_votes_count
  after_destroy :decrement_votes_count

  private

  def poll_must_be_open
    errors.add(:poll, "is not open for voting") unless poll&.open?
  end

  def choice_belongs_to_poll
    if choice && poll && choice.poll_id != poll_id
      errors.add(:choice, "does not belong to this poll")
    end
  end

  def increment_votes_count
    choice.increment!(:votes_count)
  end

  def decrement_votes_count
    choice.decrement!(:votes_count)
  end
end

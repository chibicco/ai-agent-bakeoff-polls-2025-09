class Vote < ApplicationRecord
  belongs_to :poll
  belongs_to :choice, counter_cache: true

  validates :poll, presence: true
  validates :choice, presence: true

  # 同一 Poll 内で voter_hash が重複しない（NULL/空は許容）
  validates :voter_hash, uniqueness: { scope: :poll_id }, if: -> { voter_hash.present? }

  validate :choice_belongs_to_poll
  validate :poll_is_votable

  private

  def choice_belongs_to_poll
    return if choice.nil? || poll.nil?
    errors.add(:choice, :invalid) if choice.poll_id != poll_id
  end

  def poll_is_votable
    return if poll.nil?
    errors.add(:poll, :invalid) unless poll.votable?
  end
end


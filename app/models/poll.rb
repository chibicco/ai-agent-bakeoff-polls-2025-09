class Poll < ApplicationRecord
  has_many :choices, dependent: :destroy
  has_many :votes, dependent: :destroy

  enum :status, { draft: 0, open: 1, closed: 2 }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  # 締切判定（アプリ層で close 相当の扱い）
  def ended?
    ends_at.present? && ends_at <= Time.current
  end

  # 投票可能か（公開中 かつ 締切前）
  def votable?
    open? && !ended?
  end

  # 合計投票数（カウンタキャッシュ合算で N+1 回避）
  def total_votes_count
    choices.sum(:votes_count)
  end
end


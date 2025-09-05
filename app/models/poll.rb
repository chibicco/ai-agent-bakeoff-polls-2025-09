require "securerandom"

class Poll < ApplicationRecord
  has_many :choices, dependent: :destroy
  has_many :votes, dependent: :destroy

  enum :status, { draft: 0, open: 1, closed: 2 }

  accepts_nested_attributes_for :choices, allow_destroy: true, reject_if: :all_blank

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :ensure_slug, on: :create

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

  def to_param
    slug
  end

  private

  def ensure_slug
    return if slug.present? && slug.size <= 80
    base = title.to_s.parameterize.presence || SecureRandom.hex(4)
    self.slug = base[0, 80]
  end
end

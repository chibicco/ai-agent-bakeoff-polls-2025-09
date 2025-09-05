class Poll < ApplicationRecord
  enum :status, { draft: 0, open: 1, closed: 2 }, default: :draft

  has_many :choices, dependent: :destroy
  has_many :votes, dependent: :destroy

  accepts_nested_attributes_for :choices, allow_destroy: true, reject_if: :all_blank

  validates :title, presence: true
  validates :slug, uniqueness: true, allow_blank: false

  before_validation :generate_slug, if: :new_record?

  def open?
    status == "open" && (ends_at.nil? || ends_at > Time.current)
  end

  def closed?
    status == "closed" || (ends_at.present? && ends_at <= Time.current)
  end

  private

  def generate_slug
    return if slug.present?
    return if title.blank?
    
    base_slug = title.to_s.parameterize
    
    # 日本語等でparameterizeが空になる場合の対処
    if base_slug.blank?
      base_slug = "poll-#{SecureRandom.hex(4)}"
    end
    
    counter = 0
    new_slug = base_slug
    
    while Poll.exists?(slug: new_slug)
      counter += 1
      new_slug = "#{base_slug}-#{counter}"
    end
    
    self.slug = new_slug
  end
end

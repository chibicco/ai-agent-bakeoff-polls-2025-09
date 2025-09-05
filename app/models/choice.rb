class Choice < ApplicationRecord
  belongs_to :poll
  has_many :votes, dependent: :destroy

  validates :label, presence: true
end

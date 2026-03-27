class MakeupFast < ApplicationRecord
  belongs_to :user
  has_one :makeup_allocation, dependent: :destroy

  validates :fasted_on, presence: true
  validates :fasted_on, uniqueness: { scope: :user_id }
  validate :fasted_on_cannot_be_in_the_future

  private

  def fasted_on_cannot_be_in_the_future
    return if fasted_on.blank? || fasted_on <= Date.current

    errors.add(:fasted_on, "cannot be in the future.")
  end
end

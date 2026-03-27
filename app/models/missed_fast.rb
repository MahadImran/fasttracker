class MissedFast < ApplicationRecord
  belongs_to :user
  has_one :makeup_allocation, as: :allocatable, dependent: :destroy

  validates :missed_on, presence: true, uniqueness: { scope: :user_id }
  validate :missed_on_cannot_be_in_the_future

  scope :outstanding, -> { left_outer_joins(:makeup_allocation).where(makeup_allocations: { id: nil }) }

  private

  def missed_on_cannot_be_in_the_future
    return if missed_on.blank? || missed_on <= Date.current

    errors.add(:missed_on, "cannot be in the future.")
  end
end

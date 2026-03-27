class MakeupAllocation < ApplicationRecord
  belongs_to :user
  belongs_to :makeup_fast
  belongs_to :allocatable, polymorphic: true

  validates :makeup_fast_id, uniqueness: true
end

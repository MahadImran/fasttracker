class Session < ApplicationRecord
  belongs_to :user

  normalizes :ip_address, with: ->(value) { value.presence }
  normalizes :user_agent, with: ->(value) { value.presence }
end

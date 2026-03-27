class User < ApplicationRecord
  NORMALIZED_EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\z/

  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :missed_fasts, dependent: :destroy
  has_many :ramadan_season_balances, dependent: :destroy
  has_many :makeup_fasts, dependent: :destroy
  has_many :makeup_allocations, dependent: :destroy

  normalizes :email_address, with: ->(value) { value.to_s.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: NORMALIZED_EMAIL_REGEX }

  delegate :total_owed_count,
    :total_logged_makeup_count,
    :completed_count,
    :outstanding_count,
    :exact_outstanding_count,
    :backlog_outstanding_count,
    :completion_percentage,
    :next_backlog_target,
    to: :tracker_summary

  def demo_account?
    email_address == DemoAccounts::TRACKER_EMAIL
  end

  def tracker_summary
    @tracker_summary ||= TrackerSummary.new(self)
  end

  def reload(*)
    @tracker_summary = nil
    super
  end
end

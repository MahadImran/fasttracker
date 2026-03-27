require "test_helper"

class TrackerSummaryTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email_address: "summary@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "aggregates tracker counts from exact and backlog entries" do
    @user.ramadan_season_balances.create!(gregorian_year: 2023, owed_count: 3)
    @user.missed_fasts.create!(missed_on: Date.new(2024, 3, 14))
    @user.makeup_fasts.create!(fasted_on: Date.new(2024, 4, 1))

    summary = TrackerSummary.new(@user)

    assert_equal 4, summary.total_owed_count
    assert_equal 1, summary.total_logged_makeup_count
    assert_equal 3, summary.outstanding_count
    assert_equal 1, summary.exact_outstanding_count
    assert_equal 3, summary.backlog_outstanding_count
    assert_equal 25, summary.completion_percentage
  end

  test "picks the oldest season backlog before exact missed dates" do
    older_balance = @user.ramadan_season_balances.create!(gregorian_year: 2022, owed_count: 2)
    @user.ramadan_season_balances.create!(gregorian_year: 2024, owed_count: 1)
    @user.missed_fasts.create!(missed_on: Date.new(2024, 3, 10))

    assert_equal older_balance, TrackerSummary.new(@user).next_backlog_target
  end
end

require "test_helper"

class UserJourneyTest < ActionDispatch::IntegrationTest
  test "user can sign in through the demo entry point" do
    DemoAccounts.seed_tracker!

    post demo_session_path

    assert_redirected_to dashboard_path
    follow_redirect!
    assert_response :success
    assert_match "Signed in to the demo tracker.", response.body
    assert_match "tracker@example.com", User.find_by(email_address: DemoAccounts::TRACKER_EMAIL).email_address
    assert_match "still owed", response.body
  end

  test "demo sign in fails gracefully when demo data is missing" do
    User.find_by(email_address: DemoAccounts::TRACKER_EMAIL)&.destroy

    post demo_session_path

    assert_redirected_to new_session_path
    follow_redirect!
    assert_match "Demo account not found", response.body
  end

  test "demo reset restores the seeded tracker state" do
    demo_user = DemoAccounts.seed_tracker!
    sign_in_as(demo_user)

    post quick_log_missed_dashboard_path, params: { count: 4 }
    assert_equal 8, demo_user.reload.outstanding_count

    post reset_demo_session_path
    assert_redirected_to dashboard_path
    follow_redirect!

    demo_user.reload
    assert_match "Demo tracker reset.", response.body
    assert_equal 4, demo_user.outstanding_count
    assert_equal 3, demo_user.total_logged_makeup_count
    assert_equal 2, demo_user.missed_fasts.count
  end

  test "user can register, onboard, and log a make-up fast" do
    get root_path
    assert_response :success

    post registrations_path, params: {
      user: {
        email_address: "journey@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }
    assert_redirected_to onboarding_path

    follow_redirect!
    assert_response :success

    post onboarding_path, params: { owed_count: 3 }
    assert_redirected_to dashboard_path

    follow_redirect!
    assert_response :success
    assert_match "3 still owed", response.body
    assert_match "Quick log missed", response.body

    post makeup_fasts_path, params: {
      makeup_fast: {
        fasted_on: "2025-04-01",
        notes: "First make-up fast"
      }
    }
    assert_redirected_to dashboard_path

    follow_redirect!
    assert_match "2 still owed", response.body
    assert_match "First make-up fast", MakeupFast.last.notes
  end

  test "user cannot log more make-up fasts than owed" do
    user = User.create!(
      email_address: "limit@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.ramadan_season_balances.create!(gregorian_year: 2024, hijri_year: 1445, owed_count: 1)

    sign_in_as(user)

    post makeup_fasts_path, params: { makeup_fast: { fasted_on: "2025-04-01" } }
    assert_redirected_to dashboard_path

    post makeup_fasts_path, params: { makeup_fast: { fasted_on: "2025-04-02" } }
    assert_response :unprocessable_entity
    assert_match "cannot log more make-up fasts", response.body
  end

  test "dashboard shows progress links and rejects duplicate same-day make-up logs" do
    user = User.create!(
      email_address: "progress@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.ramadan_season_balances.create!(gregorian_year: 2024, hijri_year: 1445, owed_count: 2, notes: "Travel and illness")
    user.makeup_fasts.create!(fasted_on: Date.new(2025, 4, 1), notes: "First one")
    Balances::AllocationRebuilder.new(user).call

    sign_in_as(user)

    get dashboard_path
    assert_response :success
    assert_match "50%", response.body
    assert_match "Quick log made up", response.body

    get owed_path
    assert_response :success
    assert_match "Travel and illness", response.body

    post makeup_fasts_path, params: {
      makeup_fast: {
        fasted_on: "2025-04-01",
        notes: "Duplicate"
      }
    }

    assert_response :unprocessable_entity
    assert_match "has already been taken", response.body
  end

  test "dashboard quick log actions and mobile detail pages work" do
    user = User.create!(
      email_address: "mobile-flow@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    sign_in_as(user)

    post quick_log_missed_dashboard_path, params: { count: 3 }
    assert_redirected_to dashboard_path
    assert_equal 3, user.reload.outstanding_count

    get dashboard_path
    assert_response :success
    assert_match "3 still owed", response.body

    get missed_path
    assert_response :success
    assert_match "Estimate first, then add detail when you know it", response.body

    post quick_log_makeup_dashboard_path, params: { count: 2 }
    assert_redirected_to dashboard_path
    assert_equal 2, user.reload.total_logged_makeup_count
    assert_equal 1, user.outstanding_count

    get makeup_path
    assert_response :success
    assert_match "Recent activity", response.body

    get owed_path
    assert_response :success
    assert_match "1 still open", response.body
  end

  test "user can view full history with allocation explanations" do
    user = User.create!(
      email_address: "history@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    backlog = user.ramadan_season_balances.create!(gregorian_year: 2024, hijri_year: 1445, owed_count: 1, notes: "Season estimate")
    user.missed_fasts.create!(missed_on: Date.new(2024, 3, 18), notes: "Known date")
    makeup_fast = user.makeup_fasts.create!(fasted_on: Date.new(2025, 4, 1), notes: "Completed on a Monday")
    Balances::AllocationRebuilder.new(user).call

    sign_in_as(user)

    get history_path
    assert_response :success
    assert_match "Complete history", response.body
    assert_match "Completed on a Monday", response.body
    assert_match backlog.label, response.body
    assert_match "seasonal backlog is paid down before exact dates", response.body
    assert_match makeup_fast.fasted_on.strftime("%B %-d, %Y"), response.body
  end

  test "user can filter history results" do
    user = User.create!(
      email_address: "history-filters@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.ramadan_season_balances.create!(gregorian_year: 2023, hijri_year: 1444, owed_count: 3, notes: "Travel estimate")
    user.ramadan_season_balances.create!(gregorian_year: 2024, hijri_year: 1445, owed_count: 1, notes: "Already completed")
    user.missed_fasts.create!(missed_on: Date.new(2024, 3, 18), notes: "Illness day")
    user.makeup_fasts.create!(fasted_on: Date.new(2025, 4, 1), notes: "Travel catch-up")
    user.makeup_fasts.create!(fasted_on: Date.new(2025, 4, 2), notes: "Exact-date catch-up")
    Balances::AllocationRebuilder.new(user).call

    sign_in_as(user)

    get history_path, params: {
      query: "travel",
      allocation_type: "season",
      missed_status: "outstanding",
      backlog_status: "outstanding"
    }

    assert_response :success
    assert_match "Travel catch-up", response.body
    assert_no_match "Exact-date catch-up", response.body
    assert_match "Travel estimate", response.body
    assert_no_match "Already completed", response.body
    assert_match "No exact missed dates match the current filters", response.body
  end

  test "user cannot add a missed fast in the future" do
    user = User.create!(
      email_address: "future-missed@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    sign_in_as(user)

    post missed_fasts_path, params: {
      missed_fast: {
        missed_on: (Date.current + 1).iso8601,
        notes: "Should be rejected"
      }
    }

    assert_response :unprocessable_entity
    assert_match "cannot be in the future", response.body
  end

  test "user cannot add backlog for a future season" do
    user = User.create!(
      email_address: "future-backlog@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    sign_in_as(user)

    post ramadan_season_balances_path, params: {
      ramadan_season_balance: {
        gregorian_year: Date.current.year + 1,
        owed_count: 3,
        notes: "Should be rejected"
      }
    }

    assert_response :unprocessable_entity
    assert_match "cannot be in the future", response.body
  end

  test "user cannot delete a missed fast when it would undercount owed fasts" do
    user = User.create!(
      email_address: "missed-delete@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    missed_fast = user.missed_fasts.create!(missed_on: Date.new(2024, 3, 15))
    user.makeup_fasts.create!(fasted_on: Date.new(2025, 4, 1))
    Balances::AllocationRebuilder.new(user).call

    sign_in_as(user)

    assert_no_difference("MissedFast.count") do
      delete missed_fast_path(missed_fast)
    end

    assert_redirected_to dashboard_path
    follow_redirect!
    assert_match "Delete logged make-up fasts first", response.body
  end

  test "user cannot reduce backlog below logged make-up fasts" do
    user = User.create!(
      email_address: "backlog-update@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    balance = user.ramadan_season_balances.create!(gregorian_year: 2024, hijri_year: 1445, owed_count: 2)
    2.times do |index|
      user.makeup_fasts.create!(fasted_on: Date.new(2025, 4, index + 1))
    end
    Balances::AllocationRebuilder.new(user).call

    sign_in_as(user)

    patch ramadan_season_balance_path(balance), params: {
      ramadan_season_balance: {
        gregorian_year: 2024,
        hijri_year: 1445,
        owed_count: 1,
        notes: ""
      }
    }

    assert_response :unprocessable_entity
    assert_match "cannot be reduced below the make-up fasts already logged", response.body
    assert_equal 2, balance.reload.owed_count
  end
end

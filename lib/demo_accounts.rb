module DemoAccounts
  TRACKER_EMAIL = "tracker@example.com".freeze
  NEWCOMER_EMAIL = "newcomer@example.com".freeze
  CAUGHT_UP_EMAIL = "caughtup@example.com".freeze
  PASSWORD = "password123".freeze

  module_function

  def reset_tracker_user!(user)
    user.sessions.delete_all
    user.makeup_allocations.delete_all
    user.makeup_fasts.delete_all
    user.missed_fasts.delete_all
    user.ramadan_season_balances.delete_all
  end

  def ensure_user!(email_address, password: PASSWORD)
    user = User.find_or_initialize_by(email_address: email_address)
    user.password = password
    user.password_confirmation = password
    user.save!
    reset_tracker_user!(user)
    user
  end

  def seed_newcomer!
    ensure_user!(NEWCOMER_EMAIL)
  end

  def seed_tracker!
    user = ensure_user!(TRACKER_EMAIL)
    user.ramadan_season_balances.create!(
      gregorian_year: 2022,
      hijri_year: 1443,
      owed_count: 3,
      notes: "Estimated from travel and illness."
    )
    user.ramadan_season_balances.create!(
      gregorian_year: 2023,
      hijri_year: 1444,
      owed_count: 2,
      notes: "Rough count recovered the following Ramadan."
    )
    user.missed_fasts.create!(
      missed_on: Date.new(2024, 3, 14),
      notes: "Confirmed exact date."
    )
    user.missed_fasts.create!(
      missed_on: Date.new(2024, 3, 21),
      notes: "Confirmed exact date."
    )
    user.makeup_fasts.create!(
      fasted_on: Date.new(2025, 1, 9),
      notes: "First make-up fast after rebuilding the habit."
    )
    user.makeup_fasts.create!(
      fasted_on: Date.new(2025, 1, 16),
      notes: "Kept the routine going the following week."
    )
    user.makeup_fasts.create!(
      fasted_on: Date.new(2025, 2, 3),
      notes: "Used a quieter day off work."
    )
    Balances::AllocationRebuilder.new(user).call
    user
  end

  def seed_caught_up!
    user = ensure_user!(CAUGHT_UP_EMAIL)
    user.ramadan_season_balances.create!(
      gregorian_year: 2024,
      hijri_year: 1445,
      owed_count: 1,
      notes: "Originally entered as a quick estimate."
    )
    user.missed_fasts.create!(
      missed_on: Date.new(2024, 3, 18),
      notes: "Recovered exact date later."
    )
    user.makeup_fasts.create!(
      fasted_on: Date.new(2024, 6, 10),
      notes: "Completed during Shawwal."
    )
    user.makeup_fasts.create!(
      fasted_on: Date.new(2024, 7, 1),
      notes: "Finished the last known owed fast."
    )
    Balances::AllocationRebuilder.new(user).call
    user
  end

  def seed_all!
    seed_newcomer!
    seed_tracker!
    seed_caught_up!
  end
end

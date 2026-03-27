require "test_helper"

class Balances::AllocationRebuilderTest < ActiveSupport::TestCase
  test "allocates seasonal backlog before exact missed dates" do
    user = User.create!(
      email_address: "allocator@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    backlog = user.ramadan_season_balances.create!(
      gregorian_year: 2023,
      hijri_year: 1444,
      owed_count: 2
    )
    missed_fast = user.missed_fasts.create!(missed_on: Date.new(2024, 3, 15))
    first_makeup = user.makeup_fasts.create!(fasted_on: Date.new(2025, 4, 1))
    second_makeup = user.makeup_fasts.create!(fasted_on: Date.new(2025, 4, 2))
    third_makeup = user.makeup_fasts.create!(fasted_on: Date.new(2025, 4, 3))

    Balances::AllocationRebuilder.new(user).call

    assert_equal backlog, first_makeup.reload.makeup_allocation.allocatable
    assert_equal backlog, second_makeup.reload.makeup_allocation.allocatable
    assert_equal missed_fast, third_makeup.reload.makeup_allocation.allocatable
    assert_equal 0, backlog.remaining_count
  end

  test "rejects more make-up fasts than owed fasts" do
    user = User.create!(
      email_address: "invalid-state@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.makeup_fasts.create!(fasted_on: Date.new(2025, 4, 1))

    assert_raises(Balances::AllocationRebuilder::InvalidState) do
      Balances::AllocationRebuilder.new(user).call
    end
  end
end

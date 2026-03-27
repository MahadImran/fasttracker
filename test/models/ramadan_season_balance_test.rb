require "test_helper"

class RamadanSeasonBalanceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email_address: "ramadan-balance@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "auto-populates hijri year from gregorian year when blank" do
    balance = @user.ramadan_season_balances.create!(
      gregorian_year: 2024,
      owed_count: 2
    )

    assert_equal 1445, balance.hijri_year
  end

  test "keeps a manually entered hijri year" do
    balance = @user.ramadan_season_balances.create!(
      gregorian_year: 2024,
      hijri_year: 1444,
      owed_count: 2
    )

    assert_equal 1444, balance.hijri_year
  end

  test "auto-populates gregorian year from hijri year when blank" do
    balance = @user.ramadan_season_balances.create!(
      hijri_year: 1445,
      owed_count: 2
    )

    assert_equal 2024, balance.gregorian_year
  end

  test "rejects future gregorian years" do
    balance = @user.ramadan_season_balances.new(
      gregorian_year: Date.current.year + 1,
      owed_count: 2
    )

    assert_not balance.valid?
    assert_includes balance.errors[:gregorian_year], "cannot be in the future."
  end

  test "rejects future hijri years" do
    balance = @user.ramadan_season_balances.new(
      hijri_year: RamadanSeasonBalance.current_hijri_year + 1,
      owed_count: 2
    )

    assert_not balance.valid?
    assert_includes balance.errors[:hijri_year], "cannot be in the future."
  end
end

require "test_helper"

class FastEntryValidationTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email_address: "validations@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "missed fast rejects future dates" do
    missed_fast = @user.missed_fasts.new(missed_on: Date.current + 1)

    assert_not missed_fast.valid?
    assert_includes missed_fast.errors[:missed_on], "cannot be in the future."
  end

  test "make-up fast rejects future dates" do
    makeup_fast = @user.makeup_fasts.new(fasted_on: Date.current + 1)

    assert_not makeup_fast.valid?
    assert_includes makeup_fast.errors[:fasted_on], "cannot be in the future."
  end

  test "make-up fast rejects duplicate dates for the same user" do
    @user.makeup_fasts.create!(fasted_on: Date.current)
    makeup_fast = @user.makeup_fasts.new(fasted_on: Date.current)

    assert_not makeup_fast.valid?
    assert_includes makeup_fast.errors[:fasted_on], "has already been taken"
  end
end

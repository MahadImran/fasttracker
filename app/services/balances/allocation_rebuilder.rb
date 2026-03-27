module Balances
  class AllocationRebuilder
    class InvalidState < StandardError; end

    def initialize(user)
      @user = user
    end

    def call
      raise InvalidState, "Logged make-up fasts exceed outstanding obligations." if user.total_logged_makeup_count > user.total_owed_count

      user.transaction do
        user.makeup_allocations.delete_all

        balances = user.ramadan_season_balances.oldest_first.to_a
        remaining_by_balance_id = balances.each_with_object({}) do |balance, counts|
          counts[balance.id] = balance.owed_count
        end
        missed_fasts = user.missed_fasts.order(:missed_on, :id).to_a
        missed_fast_index = 0

        user.makeup_fasts.order(:fasted_on, :id).each do |makeup_fast|
          balance = next_balance_with_remaining(balances, remaining_by_balance_id)

          if balance
            user.makeup_allocations.create!(
              makeup_fast: makeup_fast,
              allocatable: balance
            )
            remaining_by_balance_id[balance.id] -= 1
            next
          end

          allocatable = missed_fasts[missed_fast_index]
          break unless allocatable

          user.makeup_allocations.create!(
            makeup_fast: makeup_fast,
            allocatable: allocatable
          )
          missed_fast_index += 1
        end
      end
    end

    private

    attr_reader :user

    def next_balance_with_remaining(balances, remaining_by_balance_id)
      balances.find { |balance| remaining_by_balance_id[balance.id].to_i.positive? }
    end
  end
end

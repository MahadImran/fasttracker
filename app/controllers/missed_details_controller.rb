class MissedDetailsController < ApplicationController
  def show
    @missed_fast = current_user.missed_fasts.new(missed_on: Date.current)
    @ramadan_season_balance = current_user.ramadan_season_balances.new
    @missed_fasts = current_user.missed_fasts.order(missed_on: :desc, id: :desc)
    @ramadan_season_balances = current_user.ramadan_season_balances.oldest_first
  end
end

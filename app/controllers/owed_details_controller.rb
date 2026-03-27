class OwedDetailsController < ApplicationController
  def show
    @next_target = current_user.next_backlog_target
    @missed_fasts = current_user.missed_fasts.outstanding.order(:missed_on, :id)
    @ramadan_season_balances = current_user.ramadan_season_balances.oldest_first.select(&:outstanding?)
  end
end

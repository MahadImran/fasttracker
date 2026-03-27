class OnboardingsController < ApplicationController
  def show
  end

  def create
    count = params[:owed_count].to_i

    if count.negative?
      redirect_to onboarding_path, alert: "Owed fast count cannot be negative."
      return
    end

    if current_user.missed_fasts.count + count < current_user.total_logged_makeup_count
      redirect_to onboarding_path, alert: "That total is lower than the make-up fasts you have already logged."
      return
    end

    User.transaction do
      current_user.ramadan_season_balances.destroy_all

      if count.positive?
        current_user.ramadan_season_balances.create!(
          owed_count: count,
          notes: "Imported from quick-start setup"
        )
      end

      Balances::AllocationRebuilder.new(current_user).call
    end

    redirect_to dashboard_path, notice: "Your tracker is ready. Add details whenever you know them."
  rescue Balances::AllocationRebuilder::InvalidState
    redirect_to onboarding_path, alert: "That setup would leave more make-up fasts logged than you currently owe."
  end
end

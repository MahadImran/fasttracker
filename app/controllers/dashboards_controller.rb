class DashboardsController < ApplicationController
  def show
    @next_target = current_user.next_backlog_target
    @recent_makeup_fasts = current_user.makeup_fasts.order(fasted_on: :desc, id: :desc).limit(5)
    @quick_missed_count = 1
    @quick_makeup_count = 1
  end

  def quick_log_missed
    count = quick_log_count

    if count <= 0
      redirect_to dashboard_path, alert: "Enter at least 1 missed fast to add."
      return
    end

    User.transaction do
      balance = current_user.ramadan_season_balances.find_by(gregorian_year: nil, hijri_year: nil)

      if balance
        balance.update!(owed_count: balance.owed_count + count)
      else
        current_user.ramadan_season_balances.create!(owed_count: count, notes: "Quick logged backlog")
      end

      Balances::AllocationRebuilder.new(current_user).call
    end

    redirect_to dashboard_path, notice: "#{count} missed fast#{'s' unless count == 1} added to backlog."
  rescue Balances::AllocationRebuilder::InvalidState
    redirect_to dashboard_path, alert: "That quick log would leave more make-up fasts than owed fasts."
  end

  def quick_log_makeup
    count = quick_log_count

    if count <= 0
      redirect_to dashboard_path, alert: "Enter at least 1 make-up fast to log."
      return
    end

    if count > current_user.outstanding_count
      redirect_to dashboard_path, alert: "You cannot log more make-up fasts than you currently owe."
      return
    end

    dates = available_quick_makeup_dates(count)
    if dates.size < count
      redirect_to dashboard_path, alert: "We could not find enough available past dates for that quick log."
      return
    end

    MakeupFast.transaction do
      dates.each do |date|
        current_user.makeup_fasts.create!(fasted_on: date)
      end

      Balances::AllocationRebuilder.new(current_user).call
    end

    redirect_to dashboard_path, notice: "#{count} make-up fast#{'s' unless count == 1} logged using recent available dates."
  rescue Balances::AllocationRebuilder::InvalidState
    redirect_to dashboard_path, alert: "You cannot log more make-up fasts than you currently owe."
  end

  private

  def quick_log_count
    params[:count].to_i
  end

  def available_quick_makeup_dates(count)
    taken_dates = current_user.makeup_fasts.pluck(:fasted_on).index_with(true)
    dates = []
    cursor = Date.current

    while dates.size < count && cursor >= Date.new(2000, 1, 1)
      dates << cursor unless taken_dates.key?(cursor)
      cursor -= 1.day
    end

    dates
  end
end

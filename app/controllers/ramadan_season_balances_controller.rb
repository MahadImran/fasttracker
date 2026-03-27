class RamadanSeasonBalancesController < ApplicationController
  before_action :set_ramadan_season_balance, only: [ :edit, :update, :destroy ]

  def index
    redirect_to dashboard_path
  end

  def new
    @ramadan_season_balance = current_user.ramadan_season_balances.new
  end

  def edit
  end

  def create
    @ramadan_season_balance = current_user.ramadan_season_balances.new(ramadan_season_balance_params)

    if persist_with_rebalance(@ramadan_season_balance)
      redirect_to dashboard_path, notice: "Backlog entry added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    projected_total = current_user.total_owed_count - @ramadan_season_balance.owed_count + ramadan_season_balance_params[:owed_count].to_i
    if projected_total < current_user.total_logged_makeup_count
      @ramadan_season_balance.assign_attributes(ramadan_season_balance_params)
      @ramadan_season_balance.errors.add(:owed_count, "cannot be reduced below the make-up fasts already logged.")
      render :edit, status: :unprocessable_entity
      return
    end

    @ramadan_season_balance.assign_attributes(ramadan_season_balance_params)

    if persist_with_rebalance(@ramadan_season_balance)
      redirect_to dashboard_path, notice: "Backlog entry updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if current_user.total_owed_count - @ramadan_season_balance.owed_count < current_user.total_logged_makeup_count
      redirect_to dashboard_path, alert: "Delete logged make-up fasts first or add more owed fasts before removing this backlog."
      return
    end

    if destroy_with_rebalance(@ramadan_season_balance)
      redirect_to dashboard_path, notice: "Backlog entry deleted."
    else
      redirect_to dashboard_path, alert: "We could not update your balances after deleting that backlog."
    end
  end

  private

  def set_ramadan_season_balance
    @ramadan_season_balance = current_user.ramadan_season_balances.find(params[:id])
  end

  def ramadan_season_balance_params
    params.require(:ramadan_season_balance).permit(:gregorian_year, :hijri_year, :owed_count, :notes)
  end

  def persist_with_rebalance(ramadan_season_balance)
    success = false

    RamadanSeasonBalance.transaction do
      if ramadan_season_balance.save
        Balances::AllocationRebuilder.new(current_user).call
        success = true
      end
    rescue Balances::AllocationRebuilder::InvalidState
      ramadan_season_balance.errors.add(:base, "That change would leave more make-up fasts logged than you currently owe.")
      raise ActiveRecord::Rollback
    end

    success
  end

  def destroy_with_rebalance(ramadan_season_balance)
    success = false

    RamadanSeasonBalance.transaction do
      ramadan_season_balance.destroy!
      Balances::AllocationRebuilder.new(current_user).call
      success = true
    rescue Balances::AllocationRebuilder::InvalidState
      raise ActiveRecord::Rollback
    end

    success
  end
end

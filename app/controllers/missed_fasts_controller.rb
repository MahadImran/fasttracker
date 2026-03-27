class MissedFastsController < ApplicationController
  before_action :set_missed_fast, only: [ :edit, :update, :destroy ]

  def index
    redirect_to dashboard_path
  end

  def new
    @missed_fast = current_user.missed_fasts.new(missed_on: Date.current)
  end

  def edit
  end

  def create
    @missed_fast = current_user.missed_fasts.new(missed_fast_params)

    if persist_with_rebalance(@missed_fast)
      redirect_to dashboard_path, notice: "Missed fast added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @missed_fast.assign_attributes(missed_fast_params)

    if persist_with_rebalance(@missed_fast)
      redirect_to dashboard_path, notice: "Missed fast updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if current_user.total_owed_count - 1 < current_user.total_logged_makeup_count
      redirect_to dashboard_path, alert: "Delete logged make-up fasts first or add more owed fasts before removing this entry."
      return
    end

    if destroy_with_rebalance(@missed_fast)
      redirect_to dashboard_path, notice: "Missed fast deleted."
    else
      redirect_to dashboard_path, alert: "We could not update your balances after deleting that missed fast."
    end
  end

  private

  def set_missed_fast
    @missed_fast = current_user.missed_fasts.find(params[:id])
  end

  def missed_fast_params
    params.require(:missed_fast).permit(:missed_on, :notes)
  end

  def persist_with_rebalance(missed_fast)
    success = false

    MissedFast.transaction do
      if missed_fast.save
        Balances::AllocationRebuilder.new(current_user).call
        success = true
      end
    rescue Balances::AllocationRebuilder::InvalidState
      missed_fast.errors.add(:base, "That change would leave more make-up fasts logged than you currently owe.")
      raise ActiveRecord::Rollback
    end

    success
  end

  def destroy_with_rebalance(missed_fast)
    success = false

    MissedFast.transaction do
      missed_fast.destroy!
      Balances::AllocationRebuilder.new(current_user).call
      success = true
    rescue Balances::AllocationRebuilder::InvalidState
      raise ActiveRecord::Rollback
    end

    success
  end
end

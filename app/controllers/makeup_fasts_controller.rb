class MakeupFastsController < ApplicationController
  before_action :set_makeup_fast, only: [ :edit, :update, :destroy ]

  def index
    redirect_to dashboard_path
  end

  def new
    @makeup_fast = current_user.makeup_fasts.new(fasted_on: Date.current)
  end

  def edit
  end

  def create
    @makeup_fast = current_user.makeup_fasts.new(makeup_fast_params)

    if persist_with_rebalance(@makeup_fast)
      redirect_to dashboard_path, notice: "Make-up fast logged."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @makeup_fast.assign_attributes(makeup_fast_params)

    if persist_with_rebalance(@makeup_fast)
      redirect_to dashboard_path, notice: "Make-up fast updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @makeup_fast.destroy
    Balances::AllocationRebuilder.new(current_user).call
    redirect_to dashboard_path, notice: "Make-up fast deleted."
  end

  private

  def set_makeup_fast
    @makeup_fast = current_user.makeup_fasts.find(params[:id])
  end

  def makeup_fast_params
    params.require(:makeup_fast).permit(:fasted_on, :notes)
  end

  def persist_with_rebalance(makeup_fast)
    success = false

    MakeupFast.transaction do
      if makeup_fast.save
        Balances::AllocationRebuilder.new(current_user).call
        success = true
      end
    rescue Balances::AllocationRebuilder::InvalidState
      makeup_fast.errors.add(:base, "You cannot log more make-up fasts than you currently owe.")
      raise ActiveRecord::Rollback
    end

    success
  end
end

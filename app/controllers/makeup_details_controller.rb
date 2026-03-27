class MakeupDetailsController < ApplicationController
  def show
    @makeup_fast = current_user.makeup_fasts.new(fasted_on: Date.current)
    @recent_makeup_fasts = current_user.makeup_fasts.includes(:makeup_allocation).order(fasted_on: :desc, id: :desc).limit(12)
  end
end

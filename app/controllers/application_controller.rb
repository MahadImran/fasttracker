class ApplicationController < ActionController::Base
  include Authentication

  before_action :require_authentication

  helper_method :current_user, :current_tracker_summary

  private

  def current_user
    Current.user
  end

  def current_tracker_summary
    current_user&.tracker_summary
  end
end

class SessionsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create, :demo ]

  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address].to_s.downcase)

    if user&.authenticate(params[:password])
      start_new_session_for(user)
      redirect_to dashboard_path, notice: "Signed in."
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def demo
    user = User.find_by(email_address: DemoAccounts::TRACKER_EMAIL)

    if user.present?
      terminate_session
      start_new_session_for(user)
      redirect_to dashboard_path, notice: "Signed in to the demo tracker."
    else
      redirect_to new_session_path, alert: "Demo account not found. Run `bin/rails db:seed` first."
    end
  end

  def reset_demo
    unless current_user&.demo_account?
      redirect_to dashboard_path, alert: "Demo reset is only available for the demo account."
      return
    end

    user = DemoAccounts.seed_tracker!
    terminate_session
    start_new_session_for(user)
    redirect_to dashboard_path, notice: "Demo tracker reset."
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: "Signed out."
  end
end

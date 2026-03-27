module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :resume_session
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def authenticated?
    Current.user.present?
  end

  def require_authentication
    return if authenticated?

    redirect_to new_session_path, alert: "Please sign in to continue."
  end

  def resume_session
    Current.session = Session.find_by(id: cookies.signed[:session_id])
  end

  def start_new_session_for(user)
    session = user.sessions.create!(
      user_agent: request.user_agent,
      ip_address: request.remote_ip
    )

    Current.session = session
    cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
  end

  def terminate_session
    Current.session&.destroy
    cookies.delete(:session_id)
  end
end

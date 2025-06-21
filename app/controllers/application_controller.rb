class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user, :logged_in?, :show_dashboard_link?

  protected

  def require_login
    unless logged_in?
      redirect_to root_path, alert: "You must be logged in to view your profile."
    end
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def show_dashboard_link?
    return false unless logged_in?
    
    %w[global_admin alliance_admin alliance_manager].include?(current_user.role)
  end
end

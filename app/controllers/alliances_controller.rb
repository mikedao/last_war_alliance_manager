class AlliancesController < ApplicationController
  before_action :require_login

  def new
    if current_user.alliance.present?
      redirect_to dashboard_path, alert: "You already belong to an alliance."
    else
      @alliance = Alliance.new
    end
  end

  def create
    if current_user.alliance.present?
      redirect_to dashboard_path, alert: "You already belong to an alliance."
      return
    end
    @alliance = Alliance.new(alliance_params)
    @alliance.admin = current_user
    if @alliance.save
      current_user.update(role: :alliance_admin)
      redirect_to dashboard_path, notice: "Alliance created successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @alliance = current_user.alliance
    unless @alliance
      redirect_to profile_path, alert: "You do not belong to an alliance."
    end
  end

  private

  def alliance_params
    params.require(:alliance).permit(:name, :tag, :description, :server)
  end

  def require_login
    unless logged_in?
      redirect_to root_path, alert: "You must be logged in to access this page."
    end
  end
end

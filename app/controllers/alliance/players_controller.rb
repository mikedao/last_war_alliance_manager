class Alliance::PlayersController < ApplicationController
  before_action :require_login
  before_action :require_alliance_admin
  before_action :set_alliance

  def index
    @players = @alliance.players
    @players = @players.where(active: true) if params[:filter] == 'active'
    @players = @players.where(active: false) if params[:filter] == 'inactive'
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def set_alliance
    @alliance = current_user.alliance
    unless @alliance
      redirect_to dashboard_path, alert: "You must belong to an alliance to manage players."
    end
  end

  def require_alliance_admin
    unless current_user.alliance_admin?
      redirect_to dashboard_path, alert: "You must be an alliance admin to manage players."
    end
  end
end

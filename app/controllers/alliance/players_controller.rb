class Alliance::PlayersController < ApplicationController
  before_action :require_login
  before_action :require_alliance_admin
  before_action :set_alliance
  before_action :set_player, only: [:edit, :update, :destroy]

  def index
    @players = @alliance.players
    @players = @players.where(active: true) if params[:filter] == 'active'
    @players = @players.where(active: false) if params[:filter] == 'inactive'
  end

  def new
    @player = @alliance.players.build
  end

  def create
    @player = @alliance.players.build(player_params)
    
    if @player.save
      redirect_to new_alliance_player_path(@alliance), notice: 'Player created successfully!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
  end

  def destroy
    @player.destroy
    redirect_to alliance_players_path(@alliance), notice: 'Player deleted successfully!'
  end

  private

  def set_alliance
    @alliance = current_user.alliance
    unless @alliance
      redirect_to dashboard_path, alert: "You must belong to an alliance to manage players."
    end
  end

  def set_player
    @player = @alliance.players.find(params[:id])
  end

  def require_alliance_admin
    unless current_user.alliance_admin?
      redirect_to dashboard_path, alert: "You must be an alliance admin to manage players."
    end
  end

  def player_params
    params.require(:player).permit(:username, :rank, :level, :notes, :active)
  end
end

class Alliance::PlayersController < ApplicationController
  before_action :require_login
  before_action :require_alliance_admin
  before_action :set_alliance
  before_action :set_player, only: [:edit, :update, :destroy, :toggle_active]

  def index
    @players = @alliance.players
    @players = @players.where(active: true) if params[:filter] == 'active'
    @players = @players.where(active: false) if params[:filter] == 'inactive'

    respond_to do |format|
      format.html
      format.turbo_stream { render partial: 'alliance/players/table', formats: :html }
    end
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

  def bulk_add
  end

  def bulk_create
    @results = { created: [], updated: [], failed: [] }
    
    usernames = params[:usernames].to_s.split("\n").map(&:strip).reject(&:blank?)
    ranks = params[:ranks].to_s.split("\n").map(&:strip).reject(&:blank?)
    levels = params[:levels].to_s.split("\n").map(&:strip).reject(&:blank?)
    
    # Find the minimum length to process only complete sets
    min_length = [usernames.length, ranks.length, levels.length].min
    
    min_length.times do |i|
      username = usernames[i]
      rank = ranks[i]
      level = levels[i]
      
      # Validate the data
      validation_errors = validate_player_data(username, rank, level)
      
      if validation_errors.any?
        @results[:failed] << { line: i + 1, username: username, rank: rank, level: level, errors: validation_errors }
        next
      end
      
      # Find existing player or create new one
      player = @alliance.players.find_or_initialize_by(username: username)
      player.assign_attributes(
        rank: rank,
        level: level.to_i,
        notes: 'Bulk Imported',
        active: true
      )
      
      if player.save
        if player.previously_new_record?
          @results[:created] << { line: i + 1, username: username, rank: rank, level: level }
        else
          @results[:updated] << { line: i + 1, username: username, rank: rank, level: level }
        end
      else
        @results[:failed] << { line: i + 1, username: username, rank: rank, level: level, errors: player.errors.full_messages }
      end
    end
    
    render :bulk_results
  end

  def edit
  end

  def update
  end

  def destroy
    @player.destroy
    redirect_to alliance_players_path(@alliance), notice: 'Player deleted successfully!'
  end

  def toggle_active
    @player.update!(active: !@player.active?)
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "player_status_#{@player.id}",
          partial: "alliance/players/status_switch",
          locals: { player: @player, alliance: @alliance }
        )
      end
      format.html { redirect_to alliance_players_path(@alliance) }
    end
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

  def validate_player_data(username, rank, level)
    errors = []
    
    errors << "Username can't be blank" if username.blank?
    errors << "Rank can't be blank" if rank.blank?
    errors << "Level can't be blank" if level.blank?
    
    return errors if errors.any?
    
    unless %w[R1 R2 R3 R4 R5].include?(rank)
      errors << "Rank must be R1, R2, R3, R4, or R5"
    end
    
    unless level.match?(/^\d+$/) && level.to_i.between?(1, 100)
      errors << "Level must be between 1 and 100"
    end
    
    errors
  end
end

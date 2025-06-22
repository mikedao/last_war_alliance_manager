class Alliance::AllianceDuelsController < ApplicationController
  before_action :require_login
  before_action :require_alliance_admin
  before_action :set_alliance

  def index
    @alliance_duels = @alliance.alliance_duels.order(start_date: :desc)
  end

  def new
    @alliance_duel = @alliance.alliance_duels.new(start_date: Date.today)
  end

  def create
    @alliance_duel = @alliance.alliance_duels.new(alliance_duel_params)
    if @alliance_duel.save
      redirect_to alliance_duels_path, notice: "Duel created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @alliance_duel = @alliance.alliance_duels.find(params[:id])
    @alliance_duel.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("duel_row_#{@alliance_duel.id}"),
          turbo_stream.update("flash", partial: "shared/flash", locals: { message: "Duel deleted successfully.", type: "notice" })
        ]
      end
      format.html { redirect_to alliance_duels_path, notice: "Duel deleted successfully." }
    end
  end

  def show
    @alliance_duel = @alliance.alliance_duels.includes(:duel_days).find_by(start_date: params[:alliance_duel_start_date])

    if @alliance_duel.nil?
      redirect_to alliance_duels_path, alert: "Duel not found."
      return
    end

    @duel_days = @alliance_duel.duel_days.order(:day_number)
    @players = @alliance.players.order(Arel.sql("LOWER(username)"))
  end

  def update_score
    @alliance_duel = @alliance.alliance_duels.find_by(start_date: params[:alliance_duel_start_date])

    if @alliance_duel.nil?
      render json: { success: false, error: "Duel not found" }, status: :not_found
      return
    end

    player = @alliance.players.find(params[:player_id])
    duel_day = @alliance_duel.duel_days.find(params[:duel_day_id])

    # Check if day is locked
    if duel_day.locked?
      render json: { success: false, error: "Day is locked" }, status: :unprocessable_entity
      return
    end

    # Find or create the score record
    score = DuelDayScore.find_or_initialize_by(player: player, duel_day: duel_day)

    # Handle the score value
    if params[:score].blank? || params[:score] == "NA"
      score.score = nil
    else
      score.score = params[:score].to_f
    end

    if score.save
      # Calculate new total
      total = calculate_player_total(player, @alliance_duel.duel_days)

      render json: {
        success: true,
        total: total,
        score: score.score.nil? ? "NA" : score.score
      }
    else
      render json: { success: false, error: "Failed to save score" }, status: :unprocessable_entity
    end
  end

  private

  def set_alliance
    @alliance = current_user.alliance
  end

  def require_alliance_admin
    unless current_user.alliance_admin?
      redirect_to dashboard_path, alert: "You are not authorized to perform this action."
    end
  end

  def alliance_duel_params
    params.require(:alliance_duel).permit(:start_date)
  end

  helper_method :calculate_player_total

  def calculate_player_total(player, duel_days)
    total = 0.0
    duel_days.each do |day|
      score = DuelDayScore.find_by(player: player, duel_day: day)
      total += score&.score || 0.0
    end
    total.round(1)
  end
end

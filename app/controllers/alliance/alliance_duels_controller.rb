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
      redirect_to alliance_duels_path, notice: 'Duel created successfully.'
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
      format.html { redirect_to alliance_duels_path, notice: 'Duel deleted successfully.' }
    end
  end

  private

  def set_alliance
    @alliance = current_user.alliance
  end

  def require_alliance_admin
    unless current_user.alliance_admin?
      redirect_to dashboard_path, alert: 'You are not authorized to perform this action.'
    end
  end

  def alliance_duel_params
    params.require(:alliance_duel).permit(:start_date)
  end
end 

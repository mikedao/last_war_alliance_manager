class Alliance::DuelDaysController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :require_login
  before_action :require_alliance_admin
  before_action :set_alliance
  before_action :set_alliance_duel
  before_action :set_duel_day

  def edit_goal
    # This will implicitly render app/views/alliance/duel_days/edit_goal.html.erb
  end

  def update
    if @duel_day.update(duel_day_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@duel_day, :goal),
            partial: 'alliance/duel_days/duel_day_goal',
            locals: { duel_day: @duel_day }
          )
        end
        format.html { redirect_to alliance_duel_path(alliance_duel_start_date: @alliance_duel.start_date) }
      end
    else
      # Handle errors if necessary, for now, re-render the form
      render :edit_goal, status: :unprocessable_entity
    end
  end

  def cancel_edit_goal
    # This will implicitly render app/views/alliance/duel_days/cancel_edit_goal.html.erb
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

  def set_alliance_duel
    @alliance_duel = @alliance.alliance_duels.find_by!(start_date: params[:alliance_duel_start_date])
  end

  def set_duel_day
    @duel_day = @alliance_duel.duel_days.find(params[:id])
  end

  def duel_day_params
    params.require(:duel_day).permit(:score_goal)
  end
end 

class LeaderboardsController < ApplicationController
  helper_method :made_goal_stats, :missed_goal_count, :average_score

  def show
    @alliance = Alliance.where('LOWER(tag) = ?', params[:alliance_tag].downcase).first!
    
    # Find the most recent duel
    @duel = @alliance.alliance_duels.order(start_date: :desc).first
    
    # Find the latest locked day for that duel
    if @duel
      @latest_locked_day = @duel.duel_days.where(locked: true).order(updated_at: :desc).first
    end
    
  rescue ActiveRecord::RecordNotFound
    render plain: "Alliance not found", status: :not_found
  end

  private

  def made_goal_stats
    return { count: 0, total: 0, percentage: 0.0 } unless @latest_locked_day

    active_players = @alliance.players.active
    total_active_players = active_players.count
    return { count: 0, total: total_active_players, percentage: 0.0 } if total_active_players.zero?

    made_goal_count = active_players.joins(:duel_day_scores)
                                   .where(duel_day_scores: { duel_day: @latest_locked_day })
                                   .where('duel_day_scores.score >= ?', @latest_locked_day.score_goal)
                                   .count

    percentage = (made_goal_count.to_f / total_active_players * 100).round(1)
    
    { count: made_goal_count, total: total_active_players, percentage: percentage }
  end

  def missed_goal_count
    return 0 unless @latest_locked_day

    @alliance.players.active
             .joins(:duel_day_scores)
             .where(duel_day_scores: { duel_day: @latest_locked_day })
             .where('duel_day_scores.score < ?', @latest_locked_day.score_goal)
             .count
  end

  def average_score
    return 0.0 unless @latest_locked_day

    scores = @latest_locked_day.duel_day_scores
                               .joins(:player)
                               .where(players: { active: true })
                               .where.not(score: nil)
    
    return 0.0 if scores.empty?

    (scores.sum(:score) / scores.count).round(1)
  end
end 
 
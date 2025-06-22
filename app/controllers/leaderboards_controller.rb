class LeaderboardsController < ApplicationController
  helper_method :made_goal_stats, :missed_goal_count, :average_score, :top_performers, :top_weekly_performers, :players_below_goal, :naughty_list

  def show
    @alliance = Alliance.where("LOWER(tag) = ?", params[:alliance_tag].downcase).first!

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

  def top_performers
    return [] unless @latest_locked_day

    @latest_locked_day.duel_day_scores
                      .joins(:player)
                      .where(players: { active: true })
                      .where.not(score: nil)
                      .order(score: :desc)
                      .limit(10)
                      .includes(:player)
  end

  def made_goal_stats
    return { count: 0, total: 0, percentage: 0.0 } unless @latest_locked_day

    active_players = @alliance.players.active
    total_active_players = active_players.count
    return { count: 0, total: total_active_players, percentage: 0.0 } if total_active_players.zero?

    made_goal_count = active_players.joins(:duel_day_scores)
                                   .where(duel_day_scores: { duel_day: @latest_locked_day })
                                   .where("duel_day_scores.score >= ?", @latest_locked_day.score_goal)
                                   .count

    percentage = (made_goal_count.to_f / total_active_players * 100).round(1)

    { count: made_goal_count, total: total_active_players, percentage: percentage }
  end

  def missed_goal_count
    return 0 unless @latest_locked_day

    @alliance.players.active
             .joins(:duel_day_scores)
             .where(duel_day_scores: { duel_day: @latest_locked_day })
             .where("duel_day_scores.score < ?", @latest_locked_day.score_goal)
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

  def top_weekly_performers
    return [] unless @duel
    locked_days = @duel.duel_days.where(locked: true)
    return [] if locked_days.empty?

    # Sum scores for each player across all locked days
    player_scores = Player.active
      .where(alliance: @alliance)
      .joins(:duel_day_scores)
      .where(duel_day_scores: { duel_day_id: locked_days.pluck(:id) })
      .group("players.id")
      .select("players.*, SUM(duel_day_scores.score) AS total_score")
      .order("total_score DESC")
      .limit(10)

    player_scores
  end

  def players_below_goal
    return [] unless @latest_locked_day

    @latest_locked_day.duel_day_scores
                      .joins(:player)
                      .where(players: { active: true })
                      .where.not(score: nil)
                      .where("duel_day_scores.score < ?", @latest_locked_day.score_goal)
                      .order(:score)
                      .includes(:player)
  end

  def naughty_list
    return [] unless @duel
    locked_days = @duel.duel_days.where(locked: true)
    return [] if locked_days.empty?

    total_locked_days = locked_days.count

    Player.active
      .where(alliance: @alliance)
      .joins(duel_day_scores: :duel_day)
      .where(duel_day_scores: { duel_day_id: locked_days.pluck(:id) })
      .where("duel_day_scores.score < duel_days.score_goal")
      .group("players.id")
      .select("players.*, COUNT(duel_day_scores.id) as missed_days_count, (COUNT(duel_day_scores.id) * 100.0 / #{total_locked_days}) as missed_percentage")
      .having("COUNT(duel_day_scores.id) >= 3")
      .order("missed_days_count DESC")
  end
end

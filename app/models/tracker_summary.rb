class TrackerSummary
  def initialize(user)
    @user = user
  end

  def total_owed_count
    missed_count + backlog_owed_count
  end

  def total_logged_makeup_count
    makeup_count
  end

  def completed_count
    [ total_logged_makeup_count, total_owed_count ].min
  end

  def outstanding_count
    [ total_owed_count - total_logged_makeup_count, 0 ].max
  end

  def exact_outstanding_count
    @exact_outstanding_count ||= user.missed_fasts.outstanding.count
  end

  def backlog_outstanding_count
    @backlog_outstanding_count ||= [ backlog_owed_count - backlog_allocated_count, 0 ].max
  end

  def completion_percentage
    return 0 if total_owed_count.zero?

    ((completed_count.to_f / total_owed_count) * 100).round
  end

  def next_backlog_target
    @next_backlog_target ||= outstanding_backlog_scope.first || user.missed_fasts.outstanding.order(:missed_on, :id).first
  end

  private

  attr_reader :user

  def missed_count
    @missed_count ||= count_records(user.missed_fasts)
  end

  def makeup_count
    @makeup_count ||= count_records(user.makeup_fasts)
  end

  def backlog_owed_count
    @backlog_owed_count ||= user.ramadan_season_balances.sum(:owed_count)
  end

  def backlog_allocated_count
    @backlog_allocated_count ||= user.makeup_allocations.where(allocatable_type: "RamadanSeasonBalance").count
  end

  def count_records(records)
    records.loaded? ? records.size : records.count
  end

  def outstanding_backlog_scope
    user.ramadan_season_balances
      .left_outer_joins(:makeup_allocations)
      .group("ramadan_season_balances.id")
      .having("COUNT(makeup_allocations.id) < ramadan_season_balances.owed_count")
      .oldest_first
  end
end

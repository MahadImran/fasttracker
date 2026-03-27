class HistoriesController < ApplicationController
  def show
    @filters = history_filters
    @makeup_fasts = filtered_makeup_fasts
    @missed_fasts = filtered_missed_fasts
    @ramadan_season_balances = filtered_ramadan_season_balances
  end

  private

  def history_filters
    {
      query: params[:query].to_s.strip,
      allocation_type: params[:allocation_type].presence || "all",
      missed_status: params[:missed_status].presence || "all",
      backlog_status: params[:backlog_status].presence || "all"
    }
  end

  def filtered_makeup_fasts
    records = current_user.makeup_fasts.includes(makeup_allocation: :allocatable).order(fasted_on: :desc, id: :desc)

    records = case @filters[:allocation_type]
    when "season"
      records.joins(:makeup_allocation).where(makeup_allocations: { allocatable_type: "RamadanSeasonBalance" })
    when "exact"
      records.joins(:makeup_allocation).where(makeup_allocations: { allocatable_type: "MissedFast" })
    else
      records
    end

    apply_makeup_search(records)
  end

  def filtered_missed_fasts
    records = current_user.missed_fasts.includes(:makeup_allocation).order(missed_on: :desc, id: :desc)

    records = case @filters[:missed_status]
    when "outstanding"
      records.left_outer_joins(:makeup_allocation).where(makeup_allocations: { id: nil })
    when "satisfied"
      records.joins(:makeup_allocation)
    else
      records
    end

    apply_missed_search(records)
  end

  def filtered_ramadan_season_balances
    records = current_user.ramadan_season_balances.includes(makeup_allocations: :makeup_fast).oldest_first
    records = apply_backlog_search(records)

    case @filters[:backlog_status]
    when "outstanding"
      records.select(&:outstanding?)
    when "completed"
      records.reject(&:outstanding?)
    else
      records
    end
  end

  def apply_makeup_search(records)
    query = @filters[:query]
    return records if query.blank?

    query_lower = query.downcase
    records.select do |makeup_fast|
      [
        makeup_fast.fasted_on.strftime("%B %-d, %Y"),
        makeup_fast.notes,
        makeup_fast.makeup_allocation&.allocatable&.try(:label),
        makeup_fast.makeup_allocation&.allocatable&.try(:missed_on)&.strftime("%B %-d, %Y")
      ].compact.any? { |value| value.downcase.include?(query_lower) }
    end
  end

  def apply_missed_search(records)
    query = @filters[:query]
    return records if query.blank?

    query_lower = query.downcase
    records.select do |missed_fast|
      [
        missed_fast.missed_on.strftime("%B %-d, %Y"),
        missed_fast.notes
      ].compact.any? { |value| value.downcase.include?(query_lower) }
    end
  end

  def apply_backlog_search(records)
    query = @filters[:query]
    return records if query.blank?

    query_lower = query.downcase
    records.select do |balance|
      [
        balance.label,
        balance.notes,
        balance.gregorian_year&.to_s,
        balance.hijri_year&.to_s
      ].compact.any? { |value| value.downcase.include?(query_lower) }
    end
  end
end

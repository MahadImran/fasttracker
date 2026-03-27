module ApplicationHelper
  def demo_mode?
    current_user&.demo_account?
  end

  def app_theme_meta
    demo_mode? ? "Demo account" : "FastTracker"
  end

  def flash_class(type)
    case type.to_sym
    when :alert
      "flash flash-alert"
    else
      "flash flash-notice"
    end
  end

  def allocation_label(allocation)
    allocatable = allocation&.allocatable

    case allocatable
    when RamadanSeasonBalance
      allocatable.label
    when MissedFast
      allocatable.missed_on.strftime("%B %-d, %Y")
    else
      "Unallocated"
    end
  end

  def backlog_target_title(target)
    case target
    when RamadanSeasonBalance
      target.label
    when MissedFast
      target.missed_on.strftime("%B %-d, %Y")
    else
      "All caught up"
    end
  end

  def backlog_target_description(target)
    case target
    when RamadanSeasonBalance
      "#{target.remaining_count} remaining in this backlog entry."
    when MissedFast
      "Oldest known missed fast still owed."
    else
      "No outstanding fasts remain."
    end
  end

  def allocation_explanation(makeup_fast)
    allocation = makeup_fast.makeup_allocation
    allocatable = allocation&.allocatable

    case allocatable
    when RamadanSeasonBalance
      "Applied to #{allocatable.label} because seasonal backlog is paid down before exact dates."
    when MissedFast
      "Applied to the missed fast from #{allocatable.missed_on.strftime("%B %-d, %Y")} after older seasonal backlog was exhausted."
    else
      "This make-up fast is not currently allocated."
    end
  end
end

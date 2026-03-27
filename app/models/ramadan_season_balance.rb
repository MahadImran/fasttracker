class RamadanSeasonBalance < ApplicationRecord
  ISLAMIC_EPOCH = 1_948_439

  belongs_to :user
  has_many :makeup_allocations, as: :allocatable, dependent: :destroy

  before_validation :populate_hijri_year_from_gregorian_year
  before_validation :populate_gregorian_year_from_hijri_year

  validates :owed_count, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :gregorian_year, numericality: { only_integer: true, greater_than: 1900 }, allow_nil: true
  validates :hijri_year, numericality: { only_integer: true, greater_than: 1300 }, allow_nil: true
  validate :year_presence_if_not_unspecified
  validate :season_cannot_be_in_the_future

  scope :oldest_first, -> { order(Arel.sql("CASE WHEN gregorian_year IS NULL THEN 1 ELSE 0 END"), :gregorian_year, :hijri_year, :id) }

  def self.estimated_hijri_year_for(gregorian_year)
    year = gregorian_year.to_i
    return if year <= 0

    ((year - 580)..(year - 578)).find do |candidate|
      ramadan_start_for(candidate).year == year
    end || (year - 579)
  end

  def self.estimated_gregorian_year_for(hijri_year)
    year = hijri_year.to_i
    return if year <= 0

    ramadan_start_for(year).year
  end

  def self.current_hijri_year
    estimated_hijri_year_for(Date.current.year)
  end

  def allocated_count
    makeup_allocations.loaded? ? makeup_allocations.size : makeup_allocations.count
  end

  def remaining_count
    [ owed_count - allocated_count, 0 ].max
  end

  def outstanding?
    remaining_count.positive?
  end

  def label
    if gregorian_year.present? || hijri_year.present?
      [ ("Ramadan #{gregorian_year}" if gregorian_year.present?), ("Hijri #{hijri_year}" if hijri_year.present?) ].compact.join(" / ")
    else
      "Unspecified backlog"
    end
  end

  private

  def populate_hijri_year_from_gregorian_year
    return if gregorian_year.blank? || hijri_year.present?

    self.hijri_year = self.class.estimated_hijri_year_for(gregorian_year)
  end

  def populate_gregorian_year_from_hijri_year
    return if hijri_year.blank? || gregorian_year.present?

    self.gregorian_year = self.class.estimated_gregorian_year_for(hijri_year)
  end

  def year_presence_if_not_unspecified
    return if gregorian_year.present? || hijri_year.present?
    return if notes.present?

    errors.add(:base, "Add a note when saving an unspecified backlog entry.")
  end

  def season_cannot_be_in_the_future
    if gregorian_year.present? && gregorian_year > Date.current.year
      errors.add(:gregorian_year, "cannot be in the future.")
    end

    if hijri_year.present? && hijri_year > self.class.current_hijri_year
      errors.add(:hijri_year, "cannot be in the future.")
    end
  end

  def self.ramadan_start_for(hijri_year)
    days_before_ramadan = (29.5 * 8).ceil
    julian_day = 1 + days_before_ramadan + ((hijri_year - 1) * 354) + ((3 + (11 * hijri_year)) / 30) + ISLAMIC_EPOCH - 1
    Date.jd(julian_day)
  end
  private_class_method :ramadan_start_for
end

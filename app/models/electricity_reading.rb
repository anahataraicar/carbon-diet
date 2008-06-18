class ElectricityReading < ActiveRecord::Base
  # Relationships
  belongs_to :electricity_account
  # Validation
  validates_numericality_of :reading_day
  validates_numericality_of :reading_night
  # Attributes
  attr_accessible :taken_on, :reading_day, :reading_night

  protected
  def validate_on_create
    # Make sure we have not already got a reading for the date entered
    existing = electricity_account.electricity_readings.find(:first, 
                                                             :conditions => ["taken_on = ?", taken_on]) 
    errors.add("You can only enter one reading per day!", "Edit the existing entry if that's what you really meant to do.") unless existing.nil?
  end
  def validate
    # Find reading immediately before this one, and the one immediately after
    previous = electricity_account.electricity_readings.find(:first, 
                                                             :conditions => ["taken_on < ?", taken_on],
                                                             :order => "taken_on DESC") 
    subsequent = electricity_account.electricity_readings.find(:first, 
                                                               :conditions => ["taken_on > ?", taken_on])
    # Check readings, make sure they're in sequence
    errors.add("Day reading is lower than its preceeding value!", "Are you sure it's correct?") unless previous.nil? || previous.reading_day <= reading_day
    errors.add("Day reading is higher than its subsequent value!", "Are you sure it's correct?") unless subsequent.nil? || subsequent.reading_day >= reading_day
    errors.add("Night reading is lower than its preceeding value!", "Are you sure it's correct?") unless previous.nil? || previous.reading_night <= reading_night
    errors.add("Night reading is higher than its subsequent value!", "Are you sure it's correct?") unless subsequent.nil? || subsequent.reading_night >= reading_night
  end

public

  def kWh_day
    reading_day * electricity_account.electricity_unit.amount_in_kWh
  end

  def kWh_night
    reading_night * electricity_account.electricity_unit.amount_in_kWh
  end

end

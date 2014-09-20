class Event < ActiveRecord::Base
  belongs_to :group
  belongs_to :person

  scope_by_site_id
  scope :future, -> { where('starts_at >= ?', DateTime.now) }

  with_options presence: true do |e|
    e.validates :name
    e.validates :starts_at
    e.validates :group
    e.validates :person
  end
end

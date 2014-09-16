class Event < ActiveRecord::Base
  belongs_to :group
  belongs_to :person

  scope_by_site_id
  scope :future, -> { where('ends_at > ?', Time.now) }

  validates :group, presence: true
  validates :person, presence: true
end

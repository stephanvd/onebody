FactoryGirl.define do
  factory :event do
    name 'task'
    description 'My special event.'
    sequence(:starts_at) { |n| Time.now + n.days }
    sequence(:ends_at) { |n| Time.now + n.days + 1.hour }
    person
    group
  end
end

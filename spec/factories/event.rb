FactoryGirl.define do
  factory :event do
    name 'task'
    description 'My special event.'
    sequence(:starts_at) { |n| Time.now + n.days }
    sequence(:ends_at) { |n| Time.now + n.days + 1.hour }
    person
    group

    factory :nearest_future_event do
      name 'Nearest future event'
      sequence(:starts_at) { |n| 1.days.from_now.beginning_of_day + 20.hours }
      sequence(:ends_at) { |n| 1.days.from_now.beginning_of_day + 22.hours }
    end

    factory :later_future_event do
      name 'Nearest future event'
      sequence(:starts_at) { |n| 5.days.from_now.beginning_of_day + 10.hours }
      sequence(:ends_at) { |n| 5.days.from_now.beginning_of_day + 12.hours }
    end

    factory :historical_event do
      name 'Historical event'
      sequence(:starts_at) { |n| 5.days.ago }
      sequence(:ends_at) { |n| 5.days.ago + 1.hours }
    end
  end
end

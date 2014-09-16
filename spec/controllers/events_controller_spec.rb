require_relative '../spec_helper'

describe EventsController do
  describe '#index' do
    before do
      @group = FactoryGirl.create(:group)
      @person = FactoryGirl.create(:person)
      @person.groups << @group
      @event1 = FactoryGirl.create(:event,
        group: @group,
        person: @person,
        name: "Event 1",
        starts_at: 7.days.from_now.beginning_of_day + 18.hours,
        ends_at: 7.days.from_now.beginning_of_day + 19.hours
      )
      @event2 = FactoryGirl.create(:event,
        group: @group,
        person: @person,
        name: "Event 2",
        starts_at: 1.days.from_now.beginning_of_day + 20.hours,
        ends_at: 1.days.from_now.beginning_of_day + 22.hours
      )

      get :index, {group_id: @group.id}, { logged_in_id: @person.id }
    end

    it "should list events for a given group" do
      expect(assigns[:events]).to include(@event1)
    end

    it "should show upcoming events first" do
      expect(assigns[:events].first).to eq(@event2)
      expect(assigns[:events].last).to eq(@event1)
    end

    it "should not show historical events by default" do
      @historical = FactoryGirl.create(:event,
        group: @group,
        person: @person,
        name: "Event 2",
        starts_at: 5.days.ago,
        ends_at: 5.days.ago + 1.hours
      )

      expect(assigns[:events]).to have(2).items
    end
  end
end

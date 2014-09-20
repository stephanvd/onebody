require_relative '../spec_helper'

describe EventsController do
  describe '#index' do
    before do
      @group = FactoryGirl.create(:group)
      @person = FactoryGirl.create(:person)
      @person.groups << @group
      @event1 = FactoryGirl.create(:later_future_event, group: @group, person: @person)
      @event2 = FactoryGirl.create(:nearest_future_event, group: @group, person: @person)

      get :index, {group_id: @group.id}, { logged_in_id: @person.id }
    end

    it 'should list events for a given group' do
      expect(assigns[:events]).to include(@event1)
    end

    it 'should show upcoming events first' do
      expect(assigns[:events].first).to eq(@event2)
      expect(assigns[:events].last).to eq(@event1)
    end

    it 'should not show historical events by default' do
      @historical = FactoryGirl.create(:historical_event, group: @group, person: @person)
      expect(assigns[:events]).to have(2).items
    end
  end
end

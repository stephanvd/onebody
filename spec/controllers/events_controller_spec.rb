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

  describe '#new' do
    before do
      @group = FactoryGirl.create(:group)
      @person = FactoryGirl.create(:person)
      @person.groups << @group
      get :new, {group_id: @group.id}, {logged_in_id: @person.id}
    end

    it 'should show the new event form' do
      expect(response).to be_success
      post :create, {
        group_id: @group.id,
        event: {
          person_id: @person.id,
          name: 'My event',
          description: 'This event is awesome',
          starts_at: (Date.today.beginning_of_day + 10.hours),
          ends_at: (Date.today.beginning_of_day + 12.hours),
        }
      }, { logged_in_id: @person.id }
      expect(response).to be_redirect
      new_event = Event.last
      expect(new_event.name).to eq('My event')
      expect(new_event.description).to eq("This event is awesome")
      expect(new_event.starts_at).to eq(Date.today.beginning_of_day + 10.hours)
      expect(new_event.ends_at).to eq(Date.today.beginning_of_day + 10.hours)
    end
  end
end

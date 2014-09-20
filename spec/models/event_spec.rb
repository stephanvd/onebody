require 'spec_helper'

describe Event do
  it { should belong_to(:group) }
  it { should belong_to(:person) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:starts_at) }
  it { should validate_presence_of(:group) }
  it { should validate_presence_of(:person) }
  it { should_not validate_presence_of(:ends_at) }
  it { should_not validate_presence_of(:description) }

  context '#future' do
    context 'given future and historical events' do
      before do
        @group = FactoryGirl.create(:group)
        @person = FactoryGirl.create(:person)
        @person.groups << @group
        @future1 = FactoryGirl.create(:later_future_event, group: @group, person: @person)
        @future2 = FactoryGirl.create(:nearest_future_event, group: @group, person: @person)
        @historical = FactoryGirl.create(:historical_event, group: @group, person: @person)
        @events = @group.events.future
      end

      it 'should show future events' do
        expect(@events).to have(2).items
        expect(@events).to include(@future1)
        expect(@events).to include(@future2)
      end

      it 'should not show historical events' do
        expect(@group.events.future).not_to include(@historical)
      end
    end
  end
end

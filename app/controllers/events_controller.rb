class EventsController < ApplicationController
  load_and_authorize_parent :group, optional: true
  load_and_authorize_resource

  def index
    @events = @group ? @group.events.future : Event.future
  end
end

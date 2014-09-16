class EventsController < ApplicationController
  load_and_authorize_parent :group
  load_and_authorize_resource

  def index
    @events = @group.events.future
  end
end

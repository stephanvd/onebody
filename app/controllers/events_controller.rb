class EventsController < ApplicationController
  load_and_authorize_parent :group, optional: true
  load_and_authorize_resource

  def index
    @events = @group ? @group.events.future : Event.future
  end

  def new
  end

  def create
    @event = @group.events.new(params[:event])
    if @event.save
      redirect_to group_event_path(@group, @event)
    else
      render action: 'new'
    end
  end
end

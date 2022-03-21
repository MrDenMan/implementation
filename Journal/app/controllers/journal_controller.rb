class JournalController < ApplicationController
  def search
    event_id = params[:event_id]
    direction = params[:direction] # in/out
    status = params[:status] # failed/success
    visitor_id = params[:visitor_id]

    @journal = Journal.all
    
    if event_id
      @journal = @journal.where(event_id: event_id)
    end

    if direction
      @journal = @journal.where(direction: direction)
    end

    if status
      @journal = @journal.where(status: status)
    end

    if visitor_id
      @journal = @journal.where(visitor_id: visitor_id)
    end

    journal_array = []
    @journal.each{|str| journal_array.append({id: str.id, created_at: str.created_at, direction: str.direction, event_id: str.event_id, status: str.status, visitor_id: str.visitor_id})}
    render json: {journal: journal_array}, :status => 200
  end
end

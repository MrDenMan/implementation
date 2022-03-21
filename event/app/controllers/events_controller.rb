require 'net/http'
require 'bunny'
require 'eventmachine'
require 'json'


class EventsController < ApplicationController

  # GET /events or /events.json
  def index
    @events = Event.all
  end

  # GET /events/1 or /events/1.json

  #GET events/id
  def show
    #render json: Event.find(params[:id])

    @event = Event.find(params[:id])

    hash = {
      "event_id": @event.id,
      "date": @event.date,
      "categories": @event.categories,
      "created_at": @event.created_at,
    }

    render json: hash, status: 200

  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
  end

  # POST /events or /events.json
  def create

    #{"VIP" : { "all":100, "sold":10, "basic_price":2000}, "SUPERVIP" : { "all":20, "sold":5, "basic_price":5000}}

    @event = Event.new(event_params)

    respond_to do |format|
      if @event.save
        format.html { redirect_to @event, notice: "Event was successfully created." }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end

  end

  # PATCH/PUT /events/1 or /events/1.json
  def update

    #@event.date = Event.find_by_id(params[:date])
    #@event.categories = Event.find_by_id(params[:categories])
    #render :show, status: :ok, location: @event 

    respond_to do |format|
      if @event.update(event_params)
        format.html { redirect_to @event, notice: "Event was successfully updated." }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end

  end

  # DELETE /events/1 or /events/1.json
  
  def destroy

    begin
      @event = Event.find_by_id(params[:id])
      @event.destroy
      render :status => 200
    rescue
      render :status => 406
    end

  end

  def entrance
    begin
      ticket_id = params[:ticket_id]
      zone = params[:zone]
      direction = params[:direction]
      event_id = params[:event_id]

      uri = URI('http://tickets:3002/tickets?ticket_id=' << event_id.to_s)
      res = Net::HTTP.get_response(uri)

      if res.is_a?(Net::HTTPSuccess)
        json_ticket_info = ActiveSupport::HashWithIndifferentAccess.new(JSON.parse(res.body))
      else
        render :status => 503
        return
      end

      uri = URI('http://visitor:3003/' << json_ticket_info[:visitor_id].to_s)
      res = Net::HTTP.get_response(uri)

      if res.is_a?(Net::HTTPSuccess)
        json_visitor_info = ActiveSupport::HashWithIndifferentAccess.new(JSON.parse(res.body))
      else
        render :status => 503
        return
      end

      entrance_status = false 
      if (zone == json_ticket_info[:category]) and (event_id == json_ticket_info[:event_id]) and (json_ticket_info[:status] != "blocked")
        if  (direction == "in") and (json_visitor_info[:curr_event] == event_id)
          entrance_status = false
        else
          entrance_status = true
        end   
      else
        entrance_status = false
      end

      connection = Bunny.new('amqp://guest:guest@rabbitmq')
      connection.start
      channel = connection.create_channel
      exchange = channel.default_exchange
      queue_name = 'event.control'
      exchange.publish({"direction": direction, "status": entrance_status, "event_id": event_id, "visitor_id": json_ticket_info[:visitor_id]}.to_json, routing_key: queue_name)

      render :status => 200 if entrance_status == true
      render :status => 406 if entrance_status == false
    rescue
      render :status => 406
    end
  end


  #GET /tickets
  #get_info_tickets
  def get_sold_tickets
    begin
      client = HTTPClient.new
      response = client.request(:get, 'http://tickets:3002/tickets/')
    rescue Exception
      fail ExternalServiceError
    end
  end

    #GET /visitors
  def get_info_visitors
    begin
      
      id = get_sold_tickets[:visitor_id] #получить visitor_id 
      client = HTTPClient.new
      response = client.request(:get, "http://visitor:3003/visitors/#{id}")
    rescue Exception
      fail ExternalServiceError
    end
  end

  #POST curr_event /visitors
  def post_curr_event
    begin
      @event = Event.find(params[:id])

      client = HTTPClient.new
      response = client.post("http://visitor:3003/visitors/#{params[:id]}.json", {"curr_event": @event.id }.to_json, {'Content-Type' => 'application/json'})

      render :status => 200
    rescue
      render :status => 406
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.require(:event).permit(:date, :categories)
    end
end

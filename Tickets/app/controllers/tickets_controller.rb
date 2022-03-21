require 'uri'
require 'net/http'

class TicketsController < ApplicationController
  def price
    unless (params[:category] && params[:date] && params[:event_id])
      render :status => 406
      return
    end
    category = params[:category]
    date = params[:date]
    event_id = params[:event_id]


    uri = URI("http:\/\/event:3000\/events\/#{event_id}")
    res = Net::HTTP.get_response(uri)

    if res.is_a?(Net::HTTPSuccess)
      json_event_info = ActiveSupport::HashWithIndifferentAccess.new(JSON.parse(res.body))
    else
      render :status => 503
    end
    #json_event_info = ActiveSupport::HashWithIndifferentAccess.new({event_id: 1, date: "01.02.03", categories: {category1: {all: 50, sold: 6, basic_price: 2000}}}) #удалить

    unless json_event_info[:categories][category]
      render :status => 406
      return
    end

    basic_price = json_event_info[:categories][category][:basic_price].to_i
    tickets_count = json_event_info[:categories][category][:all].to_i
    sold_count = json_event_info[:categories][category][:sold].to_i

    price = basic_price
    n = (sold_count - 1).abs / (tickets_count / 10)
    n.times{|time| price = price * 1.1}

    render json: {price: price}, :status => 200
  end

  def booking
    unless (params[:category] && params[:date] && params[:event_id])
      render :status => 406
      return
    end

    category = params[:category]
    date = params[:date]
    event_id = params[:event_id]


    uri = URI("http:\/\/event:3000\/events\/#{event_id}")
    res = Net::HTTP.get_response(uri)

    if res.is_a?(Net::HTTPSuccess)
      json_event_info = ActiveSupport::HashWithIndifferentAccess.new(JSON.parse(res.body))
    else
      render :status => 503
    end

    #json_event_info = ActiveSupport::HashWithIndifferentAccess.new({event_id: 1, date: "01.02.03", categories: {category1: {all: 50, sold: 6, basic_price: 2000}}}) #удалить
    unless json_event_info[:categories][category]
      render :status => 406
      return
    end

    basic_price = json_event_info[:categories][category][:basic_price].to_i
    tickets_count = json_event_info[:categories][category][:all].to_i
    sold_count = json_event_info[:categories][category][:sold].to_i
    Ticket.booked.each do |ticket|
      if Time.now - ticket.created_at >= 300
        ticket.destroy
      end
    end
    if (sold_count + Ticket.booked.count) == tickets_count
      render :status => 406
      return
    end

    price = basic_price
    n = (sold_count - 1).abs / (tickets_count / 10)
    n.times{|time| price = price * 1.1}
    @ticket = Ticket.new(event_id: event_id, category: category, price: price)
    @ticket.booked!

    render json: {ticket_id: @ticket.id}, :status => 200
  end

  def delete
    begin
      @ticket = Ticket.find_by_id(params[:id])
      @ticket.destroy
      render :status => 200
    rescue
      render :status => 406
    end
  end

  def purchase
    unless (params[:ticket_id] && params[:first_name] && params[:last_name] && params[:middle_name] && params[:age] && params[:doc_num] && params[:doc_type])
      render :status => 406
      return
    end
    ticket_id = params[:ticket_id]
    first_name = params[:first_name]
    last_name = params[:last_name]
    middle_name = params[:middle_name]
    age = params[:age]
    doc_num = params[:doc_num]
    doc_type = params[:doc_type]

    begin  
      @ticket = Ticket.find_by_id(ticket_id)
    rescue 
      render :status => 406
      return
    end
    if @ticket.booked?
      if Time.now - @ticket.created_at>= 300
        @ticket.destroy
        render :status => 406
        return
      end

      if age <= 13
        render :status => 406
        return
      end

      uri = URI('http://visitor:3000/visitors')
      req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      req.body = {first_name: first_name, last_name: last_name, middle_name: middle_name, doc_type: doc_type, doc_num: doc_num}.to_json
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end
      if res.is_a?(Net::HTTPSuccess)
        visitor_id = ActiveSupport::HashWithIndifferentAccess.new(JSON.parse(res.body))[:visitor_id]
      else
        render :status => 503
        return
      end


      uri = URI("http:\/\/event:3000\/events\/#{event_id}")
      res = Net::HTTP.get_response(uri)

      if res.is_a?(Net::HTTPSuccess)
        json_event_info = ActiveSupport::HashWithIndifferentAccess.new(JSON.parse(res.body))
      else
        render :status => 503
      end
      

      uri = URI('http://event:3000/events')
      req = Net::HTTP::Put.new(uri, 'Content-Type' => 'application/json')
      json_event_info[categories][@ticket.category][sold] += 1
      req.body = json_event_info
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end
      unless res.is_a?(Net::HTTPSuccess)
        render :status => 503
        return
      end

      #visitor_id = 1 # удалить
      @ticket.update(visitor_id: visitor_id)
      @ticket.paid!
      
    else
      render :status => 406
      return
    end
  end

  def show
    event_id = params[:event_id]
    #f_name = params[:f_name]
    #l_name = params[:l_name]
    #m_name = params[:m_name]
    visitor_id = params[:visitor_id]
    status = params[:status]
    ticket_id = params[:ticket_id]
    category = params[:category]

    @ticket = Ticket.all

    if event_id
      @ticket = @ticket.where(event_id: event_id)
    end
    if visitor_id
      @ticket = @ticket.where(visitor_id: visitor_id)
    end
    if status
      @ticket = @ticket.where(status: status)
    end
    if ticket_id
      @ticket = @ticket.where(ticket_id: ticket_id)
    end 
    if category
      @ticket = @ticket.where(category: category)
    end

    tickets_array = []
    @ticket.each{|tick| tickets_array.append({ticket_id: tick.id, event_id: tick.event_id, price: tick.price, category: tick.category, visitor_id: tick.visitor_id, status: tick.status})}
    render json: {tickets: tickets_array}, :status => 200
  end

  def block
    begin
      @ticket = Ticket.find_by_id(params[:id])
      @ticket.blocked!
      render :status => 200
    rescue
      render :status => 406
    end
  end
end

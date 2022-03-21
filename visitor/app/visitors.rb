require 'sinatra'
require 'pg'
require 'json'
require './app/database_worker'

set :bind, '0.0.0.0'
set :port, 3000

data_base = DataBaseWorker.new

#получение информации о посетителе
get '/visitors/:id' do
  visitor_id = params[:id].to_i
  result = data_base.execute "SELECT * FROM visitors WHERE id=#{visitor_id}"
  hash_result = result[0]
  JSON.pretty_generate({ id: hash_result['id'], first_name: hash_result['first_name'],
                         last_name: hash_result['last_name'], middle_name: hash_result['middle_name'],
                         doc_type: hash_result['doc_type'], doc_num: hash_result['doc_num'],
                         curr_event: hash_result['curr_event'] })
end

#создание данных о посетителе
post '/visitors' do
  begin
    body = JSON.parse(request.body.read)
    if body["current_event"].nil?
      data_base.execute("INSERT INTO visitors (first_name,last_name,middle_name,doc_type,doc_num,curr_event)
VALUES ('#{body["first_name"]}','#{body["last_name"]}','#{body["middle_name"]}',
'#{body["doc_type"]}','#{body["doc_num"]}',NULL) ON CONFLICT DO NOTHING")
      result = data_base.execute "SELECT MAX(id) FROM visitors"
      visitor_id = result.getvalue(0, 0)
      JSON.pretty_generate({ visitor_id: "#{visitor_id}" })
    else
      data_base.execute("INSERT INTO visitors (first_name,last_name,middle_name,doc_type,doc_num,curr_event)
VALUES ('#{body["first_name"]}','#{body["last_name"]}','#{body["middle_name"]}',
'#{body["doc_type"]}','#{body["doc_num"]}', #{body["curr_event"]}) ON CONFLICT DO NOTHING")
      result = data_base.execute "SELECT MAX(id) FROM visitors"
      visitor_id = result.getvalue(0, 0)
      JSON.pretty_generate({ visitor_id: "#{visitor_id}" })
    end
  rescue StandardError
    render json: JSON.pretty_generate(
      { error: 'Ошибка доступа к внешней системе' }
    ),
           status: :service_unavailable
  end
end

#обновление данных о посетителе
put '/visitors/:id' do
  begin
    current_id = params[:id]
    body = JSON.parse(request.body.read)
    data_base.execute("UPDATE visitors SET first_name = '#{body["first_name"]}',
last_name = '#{body["last_name"]}', middle_name = '#{body["middle_name"]}', doc_type = '#{body["doc_type"]}',
doc_num = '#{body["doc_num"]}', curr_event = #{body["curr_event"]} WHERE id = #{current_id}")
  rescue StandardError
    render json: JSON.pretty_generate(
      { error: 'Ошибка доступа к внешней системе' }
    ),
           status: :service_unavailable
  end
end

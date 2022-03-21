require 'pg'

class DataBaseWorker
  def initialize
    initial_settings
    super
  end

  def execute(arg)
    connection = PG.connect host: 'db', dbname: 'visitors', user: 'user', password: 'password'
    result = connection.exec arg
    connection.close
    result
  end

  def initial_settings
    connection = PG.connect host: 'db', dbname: 'postgres', user: 'user', password: 'password'
    res_set = connection.exec "SELECT COUNT(1) FROM pg_database WHERE datname = 'visitors'"
    if res_set.getvalue(0, 0).to_i == 0
      connection.exec "CREATE DATABASE visitors"
    end
    connection.close

    execute "CREATE TABLE IF NOT EXISTS Visitors(id SERIAL PRIMARY KEY, first_name VARCHAR(30),
last_name VARCHAR(30), middle_name VARCHAR(30), doc_type VARCHAR(30), doc_num VARCHAR(11), curr_event INTEGER)"
    execute("INSERT INTO visitors (first_name,last_name, middle_name,doc_type,doc_num,curr_event)
VALUES ('Иван','Иванов','Иванович','паспорт','1122 567438', 2),
('Григорий','Иванов','Иванович','паспорт','4563 726291', 2),
('Екатерина','Петрова','Игоревна','паспорт','4512 412575', 1)
ON CONFLICT DO NOTHING")

  end
end




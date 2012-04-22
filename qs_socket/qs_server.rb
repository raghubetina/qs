require 'em-websocket'
require 'json'
require 'sequel'

DB = Sequel.sqlite("../qs/db/development.sqlite3")
$lessons, $questions, $votes = %w[lessons questions votes].map { |s| DB[s.to_sym] }

class Connection
  attr_accessor :teacher
  @@channels = {}
  def initialize ws
    @ws = ws
    @teacher = false
    ws.onmessage do |msg|
      message = JSON.parse msg
      new_message message
    end
    ws.onclose do
      send_to_all(people: -1)
      @channel.unsubscribe @sid
    end
  end

  def new_message message
    p message
    message.each do |key, value|
      send(key.to_sym, value) if respond_to?(key.to_sym)
    end
  end

  def question text
    id = $questions.insert(
                    content: text,
                    created_at: Time.now,
                    updated_at: Time.now,
                    lesson_id: @lesson_id)
    send_to_all(question: {text: text, id: id})
  end

  def lesson_id lesson_id
    @lesson_id = lesson_id
    if @@channels[lesson_id].nil?
      @teacher = true
      @@channels[lesson_id] = EM::Channel.new
    end
    @channel = @@channels[lesson_id]
    @sid = @channel.subscribe { |data| @ws.send(data) }
    send_to_all(people: 1)
  end

  def send_to_all hash
    @channel.push(JSON.unparse(hash))
  end
end


EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 3116) do |ws|
  ws.onopen { Connection.new ws }
end

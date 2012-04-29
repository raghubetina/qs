require 'em-websocket'
require 'json'
require 'sequel'
require 'cgi'

DB = Sequel.sqlite("../qs/db/development.sqlite3")
$visits, $lessons, $questions, $votes = %w[visits lessons questions votes].map { |s| DB[s.to_sym] }

class Connection
  @@lessons = {}
  @@id = 0
  def initialize ws
    @id = (@@id += 1)
    @ws = ws
    @teacher = false
    ws.onmessage { |msg| new_message msg }
    ws.onclose { close }
  end

  def new_message msg
    message = JSON.parse msg
    return if message[:question] == ''
    p message
    message.each do |key, value|
      unless %w(question note vote lesson_id).include? key
        puts "INVALID VERB: #{key}"
        next
      end
      if @lesson.nil? && key != 'lesson_id'
        puts "User not in lesson yet.  Can only set lesson_id."
        next
      end
      send(key.to_sym, value)
    end
  end

  def question text
    text = CGI.escapeHTML text
    id = $questions.insert(
                    content: text, created_at: Time.now.utc,
                    updated_at: Time.now.utc, lesson_id: @lesson[:id])
    send_to_all(question: {text: text, id: id})
  end

  def note text
    return unless @teacher
    text = CGI.escapeHTML text
    $lessons.filter(id: @lesson[:id]).update(notes: text)
    send_to_all(note: text)
  end

  def vote id
    return unless $votes.filter(user_id: @id, question_id: id).count.zero?
    $votes.insert(
           created_at: Time.now.utc, updated_at: Time.now.utc,
           user_id: @id, question_id: id)
    send_to_all(vote: id)
  end

  def lesson_id lesson_id
    if @@lessons[lesson_id].nil?
      @teacher = true
      @@lessons[lesson_id] = {
        channel: EM::Channel.new,
        number_of_connections: 0,
        id: lesson_id
      }
    end
    @lesson = @@lessons[lesson_id]
    @channel = @lesson[:channel]
    send_to_me(visit: @lesson[:number_of_connections])
    @sid = @channel.subscribe { |data| @ws.send(data) }
    visit(1)
  end

  def visit i
    $visits.insert(created_at: Time.now.utc,
            updated_at: Time.now.utc,
            delta: i,
            lesson_id: @lesson[:id])
    @lesson[:number_of_connections] += i
    send_to_all(visit: i)
  end

  def close
    return if @lesson.nil?
    @channel.unsubscribe @sid
    visit(-1)
    if @lesson[:number_of_connections].zero?
      @@lessons.delete @lesson[:id]
      @channel = @lesson = nil
    end
  end

  def send_to_me hash
    @ws.send(JSON.unparse(hash))
  end

  def send_to_all hash
    @channel.push(JSON.unparse(hash))
  end
end


EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 3116) do |ws|
  ws.onopen { Connection.new ws }
end

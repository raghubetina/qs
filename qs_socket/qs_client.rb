$LOAD_PATH << File.dirname(__FILE__) + "/web-socket-ruby/lib"
require 'web_socket'
require 'json'
require 'benchmark'

num_threads, num_messages = ARGV.map(&:to_i)

class WSClient
  @@id = 0
  def initialize num_messages, num_threads
    @num_messages = num_messages
    @num_threads = num_threads
    @num_messages_sent = @num_messages_received = @num_connections = 0
    @id = (@@id += 1)
    @client = WebSocket.new("ws://127.0.0.1:3116")
    send_message(lesson_id: 1)
    while data = @client.receive
      new_message data
      break if @num_messages_received == @num_messages && @num_messages_sent == @num_messages
    end
  end

  def new_message data
    message = JSON.parse(data)
    message.each do |key, value|
      send key.to_sym, value
    end
  end

  def question text
    @num_messages_received += 1
  end

  def send_message message
    @client.send(JSON.unparse(message))
  end

  def visit i
    @num_connections += i.to_i
    send_messages if @num_connections == @num_threads
  end

  def send_messages
    @num_messages.times do |i|
      send_message question: "Yes, I heard you!" #"from: #@id  message: #{i+1}"
      @num_messages_sent += 1
    end
  end
end

time = Benchmark.realtime do
  threads = (1..num_threads).map do |i|
    Thread.new do
      client = WSClient.new(num_messages, num_threads)
    end
  end
  threads.each(&:join)
end

time_per_question = time/(num_threads*num_messages)

# puts "Threads: #{num_threads}"
# puts "Questions/Thread: #{num_messages}"
# puts "Seconds/Question: #{time_per_question}"

puts time_per_question

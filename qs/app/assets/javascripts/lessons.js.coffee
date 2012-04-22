# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

numberOfPeople = 0

class Socket
  constructor: (url) ->
    @ws = new WebSocket(url)
    @ws.onopen = => @send(lesson_id: $("#lesson_id").text())
    @ws.onmessage = (e) => @onmessage(e)
  send: (hash) ->
    @ws.send(JSON.stringify(hash))
  onmessage: (e) ->
    for key, value of JSON.parse(e.data)
      this[key](value)
  question: (x) ->
    new Question(x.text, x.id)
  vote: (id) -> Question.find(id).mark_vote()
  answer: (id) -> Question.find(id).mark_answer()
  people: (i) ->
    numberOfPeople += i
    console.log(numberOfPeople)

class Question
  @questions: {}
  constructor: (@text, @id) ->
    Question.questions[@id] = this
  @create: (text, id) ->
    q = new Question(text, id)
    q.create_dom()
  create_dom: ->
    @dom = $("<div>").
      text(@text).
      addClass("btn btn-primary btn-large span3 question").
      insertAfter("#new_question_div")
  answer: -> socket.send(answer: @id)
  mark_answer: -> @dom.addClass('answered')
  vote: -> socket.send(vote: @id)
  mark_vote: ->
    votes = parseInt(@dom.data('votes'))
    @dom.data('votes', votes + 1)
    @colorize()
  colorize: ->
    votes = @dom.data('votes')
    score = Math.max(2.0 * votes / numberOfPeople, 1)
    channel = (255 * score).toString(16)
    console.log channel
    color = "##{channel}0000"
    console.log(color)
    @dom.css('background-color', color)
  @find: (id) ->
    Question.questions[id]
  @find_in_dom: ->
    for dom in $(".question")
      dom = $(dom)
      text = dom.text()
      id = dom.data('id')
      question = new Question(text, id)
      question.dom = dom
      question.colorize()


socket = undefined

$ ->
  socket = new Socket("ws://questionstream.in:3116")
  $("textarea").keypress((e) ->
    return unless e.keyCode is 13
    socket.send(question: $(this).val())
    $(this).val("")
    false
  )
  Question.find_in_dom()
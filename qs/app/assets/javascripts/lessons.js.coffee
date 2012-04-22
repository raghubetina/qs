jQuery ->
  $('#lesson_name').autocomplete
    source: $('#lesson_name').data('autocomplete-source')

return unless $("#lesson_id").length > 0
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
    Question.create(x.text, x.id)
  vote: (id) -> Question.find(id).mark_vote()
  answer: (id) -> Question.find(id).mark_answer()
  people: (i) ->
    numberOfPeople += i
    for id, question of Question.questions
      question.colorize()

class Question
  @questions: {}
  constructor: (@text, @id) ->
    Question.questions[@id] = this
  @create: (text, id) ->
    q = new Question(text, id)
    q.create_dom()
    q.dom.data('id', id)
    q.dom.data('votes', 0)
    q.colorize()
  create_dom: ->
    @dom = $("<div>").
      text(@text).
      addClass("btn btn-primary btn-large span3 question_div").
      insertAfter("#new_question_div")
  answer: -> socket.send(answer: @id)
  mark_answer: -> @dom.addClass('answered')
  vote: -> socket.send(vote: @id)
  mark_vote: ->
    votes = parseInt(@dom.data('votes')) + 1
    @dom.data('votes', votes)
    @colorize()
  colorize: ->
    votes = parseInt(@dom.data('votes'))
    denominator = Math.max(1, numberOfPeople)
    score = Math.min(255 * 1.3 * votes / denominator, 255)
    score = Math.floor score
    console.log votes, denominator, score
    color = "rgba(#{score}, 0, 0, 1)"
    console.log color
    @dom.css('background-color', color)
  @find: (id) ->
    Question.questions[id]
  @find_in_dom: ->
    for dom in $(".question_div")
      dom = $(dom)
      text = dom.text()
      id = dom.data('id')
      question = new Question(text, id)
      question.dom = dom
      question.colorize()

window.question = Question

socket = undefined

add_vote_click_handler = ->
  $("#question-list").on('click', '.question_div', ->
    id = parseInt($(this).data('id'))
    question = Question.find(id)
    question.vote()
  )

$ ->
  socket = new Socket("ws://questionstream.in:3116")
  $("textarea").keypress((e) ->
    return unless e.keyCode is 13
    socket.send(question: $(this).val())
    $(this).val("")
    false
  )
  setTimeout((-> Question.find_in_dom()), 300)
  add_vote_click_handler()
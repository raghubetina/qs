jQuery ->
  $('#lesson_name').autocomplete
    source: $('#lesson_name').data('autocomplete-source')

return if $("#lesson_id").length == 0 and $("#question_data").length == 0
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
      EventHandler[key](value)

EventHandler =
  question: (x) ->
    console.log 'question', x
    Question.create(x.text, x.id)
  vote: (id) ->
    console.log 'vote', id
    Question.find(id).mark_vote()
  answer: (id) -> Question.find(id).mark_answer()
  visit: (i) ->
    numberOfPeople += i
    for id, question of Question.questions
      question.colorize()
  note: (text) -> $("#teacher_note").html(text)

class Question
  @questions: {}
  constructor: (@text, @id) ->
    Question.questions[@id] = this
  @create: (text, id) ->
    q = new Question(text, id)
    q.create_dom()
  create_dom: ->
    @dom = $("<div>").
      html(@text).
      addClass("btn btn-primary span3 question_div").
      insertAfter("#new_question_div")
    @setVotes(0)
    @dom.attr('data-id', @id)
    @colorize()
  getVotes: -> parseInt(@dom.attr('data-votes'))
  setVotes: (i) -> @dom.attr('data-votes', i)
  answer: -> socket.send(answer: @id)
  mark_answer: -> @dom.addClass('answered')
  vote: -> socket.send(vote: @id)
  mark_vote: ->
    @setVotes(@getVotes() + 1)
    @colorize()
  colorize: ->
    votes = @getVotes()
    denominator = Math.max(1, numberOfPeople)
    luminance = Math.floor(100 - Math.min(50 * 2 * votes / denominator, 50))
    @dom.css('background-color', "hsl(355, 100%, #{luminance}%)")
    luminance = if luminance > 70 then 0 else 100
    @dom.css('color', "hsl(48, 0%, #{luminance}%)")
  @find: (id) ->
    Question.questions[id]
  @find_in_dom: ->
    for dom in $(".question_div")
      dom = $(dom)
      text = dom.text()
      id = parseInt(dom.attr('data-id'))
      question = new Question(text, id)
      question.dom = dom
      question.colorize()

window.question = Question

isTeacher = socket = undefined

add_vote_click_handler = ->
  $("#question-list").on('click', '.question_div', ->
    id = parseInt($(this).attr('data-id'))
    question = Question.find(id)
    question.vote()
  )

load_realtime = ->
  window.socket = socket = new Socket("ws://questionstream.in:3116")
  $("textarea").keypress((e) ->
    return unless e.keyCode is 13
    socket.send(question: $(this).val())
    $(this).val("")
    false
  )
  Question.find_in_dom()
  add_vote_click_handler()

load_playback = ->
  eventStream = JSON.parse($("#question_data").html())
  console.log eventStream
  for [time, action, id, text] in eventStream
    console.log [time, action, first, second]
    arg = if 'question' then {id: first, text: second} else first
    callback = ((action, arg) ->
      -> EventHandler[action](args)
    )(action, arg)
    setTimeout(callback, time*1000)

$ ->
  if $("#lesson_id").length > 0
    load_realtime()
  else
    load_playback()
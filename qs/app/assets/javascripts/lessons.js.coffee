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

question_timer = ->
  ta = $("#question_input")
  return if ta.length is 0
  width = ta.outerWidth()
  height = ta.outerHeight()
  outer = $("<div>").addClass('outer').height(height).width(width)
  inner = $("<div>").addClass('inner').height(height).width(0)
  inner.appendTo(outer)
  outer.prependTo("#new_question_div")
  ta.fadeOut(700).blur()
  inner.animate({width: '100%'}, 10000, ->
    ta.fadeIn(700, ->
      inner.remove()
      outer.remove()
    )
  )



EventHandler =
  question: (x) ->
    question_timer() unless playback_has_started
    Question.create(x.text, x.id)
  vote: (id) ->
    Question.find(id).mark_vote()
  answer: (id) -> Question.find(id).mark_answer()
  visit: (i) ->
    numberOfPeople += i
    for id, question of Question.questions
      question.colorize()
    $("#num_visits").text(numberOfPeople)
  note: (text) -> $("#teacher_note").html(text)

template = (html, hash) ->
  for key, value of hash
    html = html.replace("{{#{key}}}", value)
  html

class Question
  @html: """<div data-id="{{id}}" data-votes="0" class="question_div btn btn-primary">
              <i class="hide icon-thumbs-up"></i> {{text}} </div>"""
  @questions: {}
  constructor: (@text, @id) ->
    Question.questions[@id] = this
  @create: (text, id) ->
    q = new Question(text, id)
    q.create_dom()
  create_dom: ->
    html = template(Question.html, {id: @id, text: @text})
    @dom = $(html).insertAfter("#new_question_div")
    @colorize()
  getVotes: -> parseInt(@dom.attr('data-votes'))
  setVotes: (i) -> @dom.attr('data-votes', i)
  answer: -> socket.send(answer: @id)
  mark_answer: -> @dom.addClass('answered')
  vote: ->
    return if @voted_on
    @voted_on = true
    @dom.children('i').removeClass('hide')
    socket.send(vote: @id)
  hover: ->
    return if @voted_on
    @dom.children('i').toggleClass('hide')
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
  question = (t) -> Question.find(parseInt($(t).attr('data-id')))
  $("#question-list").on('click', '.question_div',
    (-> question(this).vote())
  ).on('hover', '.question_div',
    (-> question(this).hover()),
    (-> question(this).hover())
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

playback_has_started = false
load_playback = ->
  return if playback_has_started
  playback_has_started = true
  eventStream = JSON.parse($("#question_data").html())
  for [time, action, first, second] in eventStream
    arg = if action is 'question' then {id: first, text: second} else first
    callback = ((action, arg) ->
      -> EventHandler[action](arg)
    )(action, arg)
    setTimeout(callback, time*1000)

$ ->
  if $("#lesson_id").length > 0
    load_realtime()
  else
    $("#play_icon").click ->
      $(this).attr("src", "/assets/play_icon_active.png")
      load_playback()
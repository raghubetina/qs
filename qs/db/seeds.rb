# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Lesson.destroy_all
Question.destroy_all
Vote.destroy_all
Visit.destroy_all

# lessons = %w(uchack painting101 mcatochem jqueryintro sat2math)

# lessons.each do |lesson|
#   Lesson.create name: lesson,
#     embed_code: "10938654",
#     notes: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
# end

# questions = [
#   "What are the judging criteria?",
#   "When does it start?",
#   "Where is it?",
#   "How many teams have signed up?",
#   "Vim or TextMate or emacs?",
#   "Coke or Pepsi?",
#   "iPhone or Android?",
#   "Mac or Windows?",
#   "What are the prizes?"
#   ]

# Lesson.all.each do |lesson|
#   questions.each do |question|
#     q = lesson.questions.create content: question
#     rand(20).times do |u|
#       q.votes.create user_id: u
#     end
#   end
# end


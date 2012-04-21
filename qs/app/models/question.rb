class Question < ActiveRecord::Base
  belongs_to :lesson
  has_many :votes
end

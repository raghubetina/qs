class Lesson < ActiveRecord::Base
  has_many :questions
  has_many :votes, through: :questions
  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false
  validates :name, :exclusion => { :in => %w(lessons questions votes),
      :message => "Name is reserved." }
end

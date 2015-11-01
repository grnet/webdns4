class Group < ActiveRecord::Base
  has_many :domains

  validates :name, presence: true, uniqueness: true
end

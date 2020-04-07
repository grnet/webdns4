class Group < ActiveRecord::Base
  has_many :domains

  validates :name, presence: true, uniqueness: true

  has_many :memberships, dependent: :delete_all
  has_many :users, through: :memberships
end

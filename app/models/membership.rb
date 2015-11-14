class Membership < ActiveRecord::Base
  belongs_to :group
  belongs_to :user

  validates_presence_of :group
  validates_presence_of :user
end

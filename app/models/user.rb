class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :memberships
  has_many :groups, through: :memberships

  scope :orphans, -> { includes(:memberships).where(:memberships => { user_id: nil }) }
end

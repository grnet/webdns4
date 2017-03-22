class Subscription < ActiveRecord::Base
  belongs_to :domain
  belongs_to :user

  validates_presence_of :domain
  validates_presence_of :user
  validates_uniqueness_of :domain_id, scope: :user_id

  # opt-out only
  validates :disabled, inclusion: { in: [true] }, presence: true
end

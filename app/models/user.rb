class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :memberships
  has_many :groups, through: :memberships

  scope :orphans, -> { includes(:memberships).where(:memberships => { user_id: nil }) }

  # Check if the user can change his password
  #
  # Remote users are not able to change their password
  def can_change_password?
    !identifier?
  end

  def to_api
    Hash[
      :id, id,
      :email, email
    ].with_indifferent_access
  end

  def self.find_for_database_authentication(conditions)
    # Override devise method for database auth
    # We only want to auth local user via the database.

    find_first_by_auth_conditions(conditions, identifier: '')
  end
end

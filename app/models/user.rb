class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :memberships, dependent: :delete_all
  has_many :groups, through: :memberships

  has_many :subscriptions, dependent: :delete_all

  scope :orphans, -> { includes(:memberships).where(:memberships => { user_id: nil }) }

  # Check if the user can change his password
  #
  # Remote users are not able to change their password
  def can_change_password?
    !identifier?
  end

  def toggle_admin
    self.admin = !self.admin
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

  def mute_all_domains
    ActiveRecord::Base.transaction do
      domain_ids = Domain.where(group: groups).pluck(:id)
      domain_ids.each { |did|

        sub = self.subscriptions.create(domain_id: did)
        if !sub.valid?
          # Allow only domain_id (uniqueness) errors
          raise x.errors.full_messages.join(', ') if sub.errors.size > 1
          raise x.errors.full_messages.join(', ') if !sub.errors[:domain_id]
        end

      }
    end
  end
end

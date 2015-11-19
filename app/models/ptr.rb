class PTR < Record
  validates :content, presence: true, hostname: true

  before_validation :remove_terminating_dot
end


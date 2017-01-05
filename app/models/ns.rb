class NS < Record
  validates :content, presence: true, hostname: true, not_ip: true

  before_validation :remove_terminating_dot
end


class PTR < Record
  validates :content, presence: true, hostname: true
  validate :no_trailing_dot

  before_validation :remove_terminating_dot

  def no_trailing_dot
    # Do not allow PTR record names that end with a dot
    return if !short.end_with?(".")

    errors.add(:name, "PTR record name should not end with a dot")
  end

end


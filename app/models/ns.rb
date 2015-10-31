class NS < Record
  validates :content, presence: true, hostname: true
end


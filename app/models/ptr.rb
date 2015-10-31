class PTR < Record
  validates :content, presence: true, hostname: true
end


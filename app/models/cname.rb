class CNAME < Record
  validates :content, presence: true, hostname: true
end


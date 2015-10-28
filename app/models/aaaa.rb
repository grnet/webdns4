class AAAA < Record
  validates :content, presence: true, ipv6: true
  validates :name, presence: true, hostname: true
end

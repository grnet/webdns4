class A < Record
  validates :content, presence: true, ipv4: true
  validates :name, presence: true
end

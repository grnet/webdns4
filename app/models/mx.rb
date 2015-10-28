class MX < Record
  validates :content, presence: true, hostname: true
  validates :name, presence: true, hostname: true
  validates :prio, presence: true, prio: true

  def supports_prio?
    true
  end
end

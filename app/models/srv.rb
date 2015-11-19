class SRV < Record
  validates :content, presence: true
  validates :prio, presence: true, prio: true

  def supports_prio?
    true
  end
end

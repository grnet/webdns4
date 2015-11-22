class SPF < Record
  validates :content,
            format: {
              with: /\A".*"\Z/,
              message: 'SPF records should be enclosed in quotes'
            }

end

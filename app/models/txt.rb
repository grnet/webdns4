class TXT < Record
  validates :content,
            format: {
              with: /\A".*"\Z/,
              message: 'TXT records should be enclosed in quotes'
            }

end

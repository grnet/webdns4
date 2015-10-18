module LocalDb
  establish_connection "local_#{Rails.application.class.parent_name.downcase}_#{Rails.env}".to_sym
end

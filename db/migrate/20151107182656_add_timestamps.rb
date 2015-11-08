class AddTimestamps < ActiveRecord::Migration
  def change
    # TODO: Fixed in later rais-4-1
    # https://github.com/rails/rails/commit/758cbb8
    #
    # add_timestamps :domains, null: false
    # add_timestamps :records, null: false

    add_column :domains, :created_at, :datetime, null: false
    add_column :domains, :updated_at, :datetime, null: false

    add_column :records, :created_at, :datetime, null: false
    add_column :records, :updated_at, :datetime, null: false
  end
end

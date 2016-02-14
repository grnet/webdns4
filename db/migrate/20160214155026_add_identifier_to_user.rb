class AddIdentifierToUser < ActiveRecord::Migration
  def change
    add_column :users, :identifier, :string, null: :false, default: ''
    add_index :users, :identifier
  end
end

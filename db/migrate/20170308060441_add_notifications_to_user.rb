class AddNotificationsToUser < ActiveRecord::Migration
  def change
    add_column :users, :notifications, :boolean, default: true, null: false
  end
end

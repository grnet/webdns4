class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.references :domain, index: true, null: false
      t.references :user, index: true, null: false
      t.boolean :disabled, default: true, null: false

      t.timestamps
    end
  end
end

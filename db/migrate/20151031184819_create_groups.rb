class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name
      t.boolean :disabled, default: false

      t.timestamps
    end
    add_index :groups, :name, unique: true

    add_column :domains, :group_id, :integer
    add_index :domains, :group_id
  end
end

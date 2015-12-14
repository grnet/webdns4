class AddState < ActiveRecord::Migration
  def change
    add_column :domains, :state, :string, default: 'initial', null: false
  end
end

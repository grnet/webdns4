class CreateDnssecPolicies < ActiveRecord::Migration
  def change
    create_table :dnssec_policies do |t|
      t.string :name
      t.boolean :active
      t.text :policy

      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

    end

    add_column :domains, :dnssec_policy_id, :integer, default: nil
  end
end

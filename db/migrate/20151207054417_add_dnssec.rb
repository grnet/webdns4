class AddDnssec < ActiveRecord::Migration
  def change
    add_column :domains, :dnssec, :boolean, default: false, null: false
    add_column :domains, :dnssec_parent, :string, default: '', null: false
    add_column :domains, :dnssec_parent_authority, :string, default: '', null: false
  end
end

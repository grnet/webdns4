class AddAdminToUsers < ActiveRecord::Migration
  def change
    add_column :users, :admin, :boolean
    User.find_each do |u|
      u.admin = u.groups.where(name: WebDNS.settings[:admin_group]).exists?
      u.save
    end
  end
end

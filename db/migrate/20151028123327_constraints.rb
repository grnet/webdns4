class Constraints < ActiveRecord::Migration
  def up
    execute <<-SQL.gsub(/\s+/, ' ').strip
      ALTER TABLE `records` ADD CONSTRAINT `records_ibfk_1` FOREIGN KEY (`domain_id`)
      REFERENCES `domains` (`id`) ON DELETE CASCADE;
    SQL
  end

  def down
    execute 'ALTER TABLE `records` DROP FOREIGN KEY `records_ibfk_1`'
  end
end

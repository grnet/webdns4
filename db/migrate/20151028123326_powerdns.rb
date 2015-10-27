class Powerdns < ActiveRecord::Migration
  def up
    raw_sql = File.read Rails.root.join('db', 'pdns_schema.sql')

    raw_sql.split(';').each { |stmt|
      execute(stmt.strip) if stmt.present?
    }
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end

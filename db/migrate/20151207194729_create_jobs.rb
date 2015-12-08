class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string :job_type, null: false
      t.references :domain, index: true
      t.string :args, null: false
      t.integer :status, default: 0, null: false
      t.integer :retries, default: 0, null: false

      t.timestamps
    end
  end
end

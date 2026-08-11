class CreateJobLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :job_logs do |t|
      t.string :job_type
      t.string :status
      t.datetime :started_at
      t.datetime :ended_at
      t.jsonb :metadata

      t.timestamps
    end
  end
end

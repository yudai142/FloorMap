class JobLog < ApplicationRecord
  validates :job_type, :status, presence: true
  enum :status, { success: 'success', failure: 'failure', error: 'error' }

  scope :by_job_type, ->(type) { where(job_type: type) }
  scope :successful, -> { where(status: :success) }
  scope :failed, -> { where(status: [:failure, :error]) }
  scope :recent, -> { order(created_at: :desc) }

  def execution_time
    return nil if ended_at.nil?

    (ended_at - started_at).to_i
  end
end

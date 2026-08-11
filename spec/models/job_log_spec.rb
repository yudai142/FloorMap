require 'rails_helper'

RSpec.describe JobLog, type: :model do
  describe 'validations' do
    it 'is valid with all required attributes' do
      job_log = build(:job_log)
      expect(job_log).to be_valid
    end

    it 'is invalid without job_type' do
      job_log = build(:job_log, job_type: nil)
      expect(job_log).not_to be_valid
    end

    it 'is invalid without status' do
      job_log = build(:job_log, status: nil)
      expect(job_log).not_to be_valid
    end
  end

  describe 'associations' do
    it { should have_many(:job_logs).dependent(:destroy) }
  end

  describe 'scopes' do
    before do
      @success_log = create(:job_log, job_type: 'CheckDailyAutoCheckoutJob', status: :success)
      @failure_log = create(:job_log, job_type: 'CheckDailyAutoCheckoutJob', status: :failure)
      @error_log = create(:job_log, job_type: 'CheckDailyAutoCheckoutJob', status: :error)
    end

    describe '.by_job_type' do
      it 'filters by job_type' do
        logs = JobLog.by_job_type('CheckDailyAutoCheckoutJob')
        expect(logs.count).to eq(3)
      end
    end

    describe '.successful' do
      it 'returns only successful logs' do
        logs = JobLog.successful
        expect(logs).to include(@success_log)
        expect(logs).not_to include(@failure_log)
        expect(logs).not_to include(@error_log)
      end
    end

    describe '.failed' do
      it 'returns logs with failure or error status' do
        logs = JobLog.failed
        expect(logs).to include(@failure_log)
        expect(logs).to include(@error_log)
        expect(logs).not_to include(@success_log)
      end
    end

    describe '.recent' do
      it 'returns logs ordered by created_at desc' do
        new_log = create(:job_log)
        logs = JobLog.recent.limit(1)
        expect(logs.first).to eq(new_log)
      end
    end
  end

  describe '#metadata' do
    it 'stores metadata as JSON' do
      metadata = { checked_out_count: 5, expired_count: 3 }
      job_log = create(:job_log, metadata: metadata)

      expect(job_log.metadata['checked_out_count']).to eq(5)
      expect(job_log.metadata['expired_count']).to eq(3)
    end
  end

  describe '#execution_time' do
    it 'calculates execution time' do
      start_time = Time.current
      end_time = start_time + 2.seconds
      job_log = create(:job_log, started_at: start_time, ended_at: end_time)

      expect(job_log.execution_time).to be_within(0.1).of(2.0)
    end

    it 'returns nil when ended_at is nil' do
      job_log = create(:job_log, ended_at: nil)
      expect(job_log.execution_time).to be_nil
    end
  end
end

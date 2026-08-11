class Admin::JobLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!
  before_action :set_job_log, only: :show

  def index
    @job_logs = JobLog.recent.page(params[:page]).per(20)
    @job_logs = @job_logs.by_job_type(params[:job_type]) if params[:job_type].present?
    @job_logs = @job_logs.send(params[:status]) if params[:status].present? && %w[successful failed].include?(params[:status])
  end

  def show
  end

  private

  def set_job_log
    @job_log = JobLog.find(params[:id])
  end

  def authorize_admin!
    redirect_to root_path, alert: "Unauthorized" unless current_user.admin?
  end
end

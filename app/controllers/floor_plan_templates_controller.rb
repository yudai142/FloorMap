class FloorPlanTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_template, only: [ :show, :destroy ]
  before_action :authorize_user, only: [ :destroy ]

  def index
    @my_templates = current_user.floor_plan_templates.recent
    @public_templates = FloorPlanTemplate.public_templates.recent
  end

  def show
  end

  def create
    @template = current_user.floor_plan_templates.build(template_params)

    if @template.save
      redirect_to floor_plan_templates_path, notice: "テンプレートが作成されました"
    else
      redirect_to floor_plan_templates_path, alert: @template.errors.full_messages.join(", ")
    end
  end

  def destroy
    @template.destroy
    redirect_to floor_plan_templates_path, notice: "テンプレートが削除されました"
  end

  private

  def set_template
    @template = FloorPlanTemplate.find(params[:id])
  end

  def authorize_user
    redirect_to root_path unless @template.user == current_user || current_user.admin?
  end

  def template_params
    params.require(:floor_plan_template).permit(:name, :description, :floor_plan_data, :is_public)
  end
end

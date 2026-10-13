class FloorPlanTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_template, only: [ :show, :destroy, :edit, :update, :save_floor_plan ]
  before_action :authorize_user, only: [ :destroy, :edit, :update, :save_floor_plan ]

  def index
    @my_templates = current_user.floor_plan_templates.recent
    @public_templates = FloorPlanTemplate.public_templates.recent

    render inertia: "FloorPlanTemplates/Index", props: {
      my_templates: @my_templates.map { |t| template_json(t) },
      public_templates: @public_templates.map { |t| template_json(t) },
      **default_inertia_props
    }
  end

  def new
    @template = current_user.floor_plan_templates.build(
      name: "新規テンプレート",
      description: "",
      is_public: false,
      floor_plan_data: {}
    )

    Rails.logger.info("Creating new template: #{@template.inspect}")

    if @template.save
      Rails.logger.info("Template created successfully: #{@template.id}")
      render inertia: "FloorPlanTemplates/CanvasEditor", props: canvas_editor_props(@template).merge(is_new: true)
    else
      Rails.logger.error("Failed to create template: #{@template.errors.full_messages.inspect}")
      redirect_to floor_plan_templates_path, alert: "テンプレート作成に失敗しました: #{@template.errors.full_messages.join(", ")}"
    end
  end

  def edit
    render inertia: "FloorPlanTemplates/CanvasEditor", props: canvas_editor_props(@template)
  end

  def show
    render inertia: "FloorPlanTemplates/Show", props: {
      template: template_json(@template),
      **default_inertia_props
    }
  end

  def create
    # 他の create アクションは不要（new で自動作成）
    head :no_content
  end

  def update
    # テンプレート詳細フォームから呼び出される
    if @template.update(template_params)
      redirect_to floor_plan_templates_path, notice: "テンプレートが保存されました"
    else
      render inertia: "FloorPlanTemplates/Details", props: {
        template: template_json(@template),
        errors: @template.errors.messages,
        **default_inertia_props
      }, status: :unprocessable_entity
    end
  end

  def save_floor_plan
    if @template.update(floor_plan_data_params)
      render json: { floor_plan_data: @template.floor_plan_data }, status: :ok
    else
      render json: { errors: @template.errors.messages }, status: :unprocessable_entity
    end
  end

  def details
    render inertia: "FloorPlanTemplates/Details", props: {
      template: template_json(@template),
      **default_inertia_props
    }
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

  def floor_plan_data_params
    params.require(:floor_plan_template).permit(floor_plan_data: [ :id, :type, :x, :y, :x1, :y1, :x2, :y2, :cx, :cy, :r, :width, :height, :color, :lineWidth, :text, :points, :pointsArray, :fill ])
  end

  def canvas_editor_props(template)
    {
      template: template_json(template),
      shapes_data: template.floor_plan_data || [],
      seats: template.template_seats.order(:id).map(&:canvas_json),
      current_user: current_user.as_json(only: [ :id, :email ]),
      **default_inertia_props
    }
  end

  def template_json(template)
    {
      id: template.id,
      name: template.name,
      description: template.description,
      is_public: template.is_public,
      usage_count: template.usage_count,
      user: { id: template.user.id, username: template.user.username },
      created_at: template.created_at.iso8601
    }
  end
end

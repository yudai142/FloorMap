class FloorPlanTemplate < ApplicationRecord
  belongs_to :user
  has_many :rooms, dependent: :nullify
  has_many :template_seats, class_name: "FloorPlanTemplateSeat", dependent: :destroy
  has_one_attached :preview_image

  validates :name, presence: true, length: { minimum: 1, maximum: 255 }
  validate :floor_plan_data_is_valid_jsonb

  scope :public_templates, -> { where(is_public: true) }
  scope :readable_by, ->(user) { user.admin? ? all : where(user_id: user.id).or(where(is_public: true)) }
  scope :by_user, ->(user) { where(user_id: user.id) }
  scope :popular, -> { order(usage_count: :desc) }
  scope :recent, -> { order(created_at: :desc) }

  def public?
    is_public
  end

  def increment_usage!
    increment!(:usage_count)
  end

  private

  def floor_plan_data_is_valid_jsonb
    return if floor_plan_data.is_a?(Array) || floor_plan_data.is_a?(Hash)

    errors.add(:floor_plan_data, "must be a valid JSON structure")
  end
end

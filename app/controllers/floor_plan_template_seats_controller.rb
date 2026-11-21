class FloorPlanTemplateSeatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_template
  before_action :set_seat, only: [ :position, :destroy ]

  def create
    seat = @template.template_seats.build(seat_params)

    if seat.save
      render json: seat_json(seat), status: :created
    else
      render json: { errors: seat.errors.messages }, status: :unprocessable_entity
    end
  end

  def position
    if @seat.update(position_params)
      render json: seat_json(@seat), status: :ok
    else
      render json: { errors: @seat.errors.messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @seat.destroy
    head :no_content
  end

  private

  def set_template
    @template = FloorPlanTemplate.find(params[:floor_plan_template_id])
    head :forbidden unless @template.user == current_user || current_user.admin?
  end

  def set_seat
    @seat = @template.template_seats.find(params[:id])
  end

  def seat_params
    params.require(:seat).permit(:position_x, :position_y, :seat_type)
  end

  def position_params
    params.require(:seat).permit(:position_x, :position_y)
  end

  def seat_json(seat)
    {
      id: seat.id,
      seat_identifier: "S#{seat.id}",
      position_x: seat.position_x,
      position_y: seat.position_y,
      seat_type: seat.seat_type
    }
  end
end

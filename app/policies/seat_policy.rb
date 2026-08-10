class SeatPolicy < ApplicationPolicy
  def show?
    user.owner_of?(@record.room) || user.has_permission_in?(@record.room) || user.admin?
  end

  def create?
    user.owner_of?(@record.room) || user.admin?
  end

  def update?
    user.owner_of?(@record.room) || user.admin?
  end

  def destroy?
    user.owner_of?(@record.room) || user.admin?
  end

  def index?
    user.owner_of?(@record.room) || user.has_permission_in?(@record.room) || user.admin?
  end
end

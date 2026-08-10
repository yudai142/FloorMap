class RoomPolicy < ApplicationPolicy
  def show?
    user.owner_of?(@record) || user.has_permission_in?(@record)
  end

  def create?
    user.manager? || user.admin?
  end

  def update?
    user.owner_of?(@record)
  end

  def destroy?
    user.owner_of?(@record)
  end
end

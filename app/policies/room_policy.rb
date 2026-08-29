class RoomPolicy < ApplicationPolicy
  def show?
    user.owner_of?(@record) || user.has_permission_in?(@record)
  end

  def index?
    true
  end

  def new?
    true
  end

  def create?
    true
  end

  def update?
    user.owner_of?(@record)
  end

  def destroy?
    user.owner_of?(@record)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.joins("LEFT JOIN room_permissions ON room_permissions.room_id = rooms.id")
          .where("rooms.user_id = ? OR room_permissions.user_id = ?", user.id, user.id)
          .distinct
      end
    end
  end
end

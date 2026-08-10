class RoomPermissionPolicy < ApplicationPolicy
  def create?
    return true if user.admin?
    return true if user.manager?

    false
  end

  def destroy?
    return true if user.admin?
    return true if user.manager?

    false
  end
end

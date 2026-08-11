class VisitorPolicy
  attr_reader :user, :visitor

  def initialize(user, visitor)
    @user = user
    @visitor = visitor
  end

  def edit?
    user.nil? || visitor_belongs_to_user?
  end

  def update?
    edit?
  end

  def check_in?
    true
  end

  def check_out?
    user.nil? || visitor_belongs_to_user?
  end

  private

  def visitor_belongs_to_user?
    visitor.sessions.active.any? { |session| session.user_id == user.id }
  end
end

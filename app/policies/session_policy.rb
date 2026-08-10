class SessionPolicy < ApplicationPolicy
  def check_in?
    # ユーザーが既にアクティブなセッションを持っていないかチェック
    !user.sessions.active.exists?
  end

  def check_out?
    user.id == @record.user_id || user.admin?
  end

  def view?
    user.id == @record.user_id || user.admin?
  end

  def history?
    true
  end
end

class Users::SessionsController < Devise::SessionsController
  def after_sign_in_path_for(resource)
    transfer_visitor_seats(resource)
    super
  end

  private

  def transfer_visitor_seats(user)
    # セッションから訪問者IDを取得
    visitor_id = session[:visitor_id]
    return if visitor_id.blank?

    # 訪問者レコードを取得
    visitor = Visitor.find_by(id: visitor_id)
    return if visitor.nil?

    # 訪問者のアクティブセッションの座席をユーザーの座席に移譲
    visitor.sessions.active.each do |session|
      session.update(
        user_id: user.id,
        visitor_id: nil
      )
    end

    # セッションから訪問者IDを削除
    session.delete(:visitor_id)

    # 訪問者レコードを削除
    visitor.destroy
  end
end

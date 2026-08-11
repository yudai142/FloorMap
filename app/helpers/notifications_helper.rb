module NotificationsHelper
  def notification_type_label(notification_type)
    case notification_type
    when "check_in"
      "チェックイン"
    when "check_out"
      "チェックアウト"
    when "system_update"
      "システム更新"
    when "warning"
      "警告"
    else
      "その他"
    end
  end

  def notification_type_color(notification_type)
    case notification_type
    when "check_in"
      "text-blue-500"
    when "check_out"
      "text-slate-600"
    when "system_update"
      "text-green-600"
    when "warning"
      "text-red-500"
    else
      "text-slate-600"
    end
  end
end

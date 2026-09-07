module ErrorMessagesHelper
  def custom_error_message(error)
    case error.type
    when :taken
      case error.attribute
      when :email
        "このメールアドレスは既に登録されています。"
      when :username
        "このユーザー名は既に登録されています。"
      else
        error.message
      end
    when :blank
      case error.attribute
      when :email
        "メールアドレスを入力してください"
      when :username
        "ユーザー名を入力してください"
      when :password
        "パスワードを入力してください"
      when :password_confirmation
        "パスワード確認を入力してください"
      else
        error.message
      end
    when :too_short
      case error.attribute
      when :username
        "ユーザー名は3文字以上で入力してください"
      when :password
        "パスワードは6文字以上で入力してください"
      else
        error.message
      end
    when :confirmation
      case error.attribute
      when :password_confirmation
        "パスワード確認がパスワードと一致しません"
      else
        error.message
      end
    else
      error.message
    end
  end
end

module ErrorMessagesHelper
  def convert_flash_alert(message)
    case message
    # 英語のメッセージ
    when /Invalid Email or password/, /invalid email or password/i
      "メールアドレスまたはパスワードが正しくありません"
    when /You need to sign in or sign up before continuing/, /unauthenticated/i
      "ログインしてください"
    when /confirmation instructions/, /confirm/i
      "メールアドレスを確認してください"
    when /already confirmed/i
      "既に確認されています"
    # 日本語のメッセージ（Devise の i18n で既に日本語）
    when /無効な.*またはパスワード/
      "メールアドレスまたはパスワードが正しくありません"
    when /続行する前に/
      "ログインしてください"
    when /既にサインイン/
      "既にサインインしています"
    when /アカウントが.*有効化されていません/
      "アカウントがまだ有効化されていません"
    when /ロックされています/
      "アカウントがロックされています"
    when /タイムアウト/
      "セッションがタイムアウトしました。もう一度サインインしてください"
    else
      message
    end
  end

  def devise_error_message(error)
    case error.type
    when :invalid
      "メールアドレスまたはパスワードが正しくありません"
    when :not_found_in_database
      "メールアドレスまたはパスワードが正しくありません"
    when :unauthenticated
      "ログインしてください"
    else
      error.message
    end
  end

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

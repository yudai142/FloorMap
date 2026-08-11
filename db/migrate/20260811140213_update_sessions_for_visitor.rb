class UpdateSessionsForVisitor < ActiveRecord::Migration[8.1]
  def change
    # user_id を NULL 許可に変更
    change_column_null :sessions, :user_id, true

    # visitor_id を追加
    add_column :sessions, :visitor_id, :bigint, if_not_exists: true
    add_foreign_key :sessions, :visitors, if_not_exists: true
    add_index :sessions, :visitor_id, if_not_exists: true
  end
end

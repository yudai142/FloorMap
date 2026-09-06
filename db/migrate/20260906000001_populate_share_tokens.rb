class PopulateShareTokens < ActiveRecord::Migration[8.1]
  def up
    Room.where(share_token: nil).find_each do |room|
      token = loop do
        generated_token = SecureRandom.hex(6)
        break generated_token unless Room.exists?(share_token: generated_token)
      end
      room.update_column(:share_token, token)
    end
  end
end

class AutoCheckoutJob < ApplicationJob
  queue_as :default

  def perform(session_id)
    session = Session.find_by(id: session_id)
    return unless session

    session.check_out!
  end
end

class StopEvent < ActiveRecord::Base
  extend SuspectEvent
  belongs_to :reading
  belongs_to :device
  include ApplicationHelper
end

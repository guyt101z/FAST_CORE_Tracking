require 'test_helper'

class SuspectEventTest < ActiveSupport::TestCase
    fixtures :trip_events

    def test_suspect_events
        TripEvent.identify_suspect_events(RAILS_DEFAULT_LOGGER)

        assert_equal 3, TripEvent.count(:conditions => {:suspect => true})
        
        assert_equal true, trip_events(:suspect_overlapping_a).suspect
        assert_equal true, trip_events(:suspect_overlapping_b).suspect
        assert_equal true, trip_events(:suspect_overlapped_a).suspect
        assert_equal false, trip_events(:suspect_overlapped_b).suspect
    end
end

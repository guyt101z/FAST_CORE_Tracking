require 'test_helper'
require 'readings_controller'

# Re-raise errors caught by the controller.
class ReadingsController; def rescue_action(e) raise e end; end

class ReadingsControllerTest < ActionController::TestCase
  
  fixtures :users,:accounts,:readings,:devices
  
  def setup
    @controller = ReadingsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_recent
    get :recent, {}, {:user=>users(:testuser), :account_id => accounts(:app).id}
    assert_response :success
  end

  def test_last
    @request.host="app.ublip.com"
    @request.env["Authorization"] = "Basic " + Base64.encode64("testuser@ublip.com:testing")
    get :last, { :id => "1"}, {:user => users(:testuser), :user_id => users(:testuser), :account_id => accounts(:app)}
    
    assert_select "channel>item" do |element|
       assert_tag :tag => "georss:point", :content => "32.63585 -97.17569"
    end
  end
  
  def test_all
    @request.host = "app.ublip.com"
     @request.env["Authorization"] = "Basic " + Base64.encode64("testuser@ublip.com:testing")
     get :all, {}, {:user => users(:testuser), :user_id => users(:testuser), :account_id => accounts(:app)}
     # Simple test to validate there are 5 items in the georss response
     assert_select "channel item", 5
  end
  
  def test_last_not_auth
    @request.host="app.ublip.com"
    @request.env["Authorization"] = "Basic " + Base64.encode64("testuser@ublip.com:testing")
    get :last, { :id => 7}, {:user => users(:testuser), :user_id => users(:testuser), :account_id => accounts(:app)}
    
    assert_select "channel" do |element|
      element[0].children.each do |tag|
        if tag.class==HTML::Tag && tag.name=="item"
          fail("should not return any content")
        end
      end      
    end
  end
  
  def test_last_for_session_user
      @request.host="app.ublip.com"
      get :last, { :id => 1}, {:user => users(:testuser), :user_id => users(:testuser), :account_id => accounts(:app)}
      assert_select "channel item", 1
  end

  def test_all_for_session_user
      @request.host="app.ublip.com"
      get :all, {}, {:user => users(:testuser), :user_id => users(:testuser), :account_id => accounts(:app)}
      assert_select "channel item", 5
  end

  # Make sure that we're requiring HTTP auth
  def test_require_http_auth_for_last
    @request.host="app.ublip.com"
    get :last, {:id => 1}#, {:user => users(:testuser), :user_id => users(:testuser), :account_id => accounts(:app)}
    assert_equal @response.body, "Couldn't authenticate you"
  end  
  
  # Make sure that we're requiring HTTP auth
  def test_require_http_auth_for_all
    @request.host="app.ublip.com"
    get :all, {}#, {:user => users(:testuser), :user_id => users(:testuser), :account_id => accounts(:app)}
    assert_equal @response.body, "Couldn't authenticate you"
  end
  
  # Test public feed
  def test_public_feed
    @request.host = "app.ublip.com"
    get :public
    assert_select "channel item", 1
    assert_select "channel item speed", 1
    assert_select "channel item direction", 1 
  end
  
end

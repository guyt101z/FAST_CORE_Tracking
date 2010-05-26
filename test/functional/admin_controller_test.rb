require 'test_helper'
require 'admin_controller'

# Re-raise errors caught by the controller.
class AdminController; def rescue_action(e) raise e end; end

class AdminControllerTest < ActionController::TestCase
  
  fixtures :users, :accounts, :devices, :device_profiles

  def setup
    @controller = AdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_not_logged_in
    get :index
    assert_redirected_to :controller => "home"
  end
  
  def test_super_admin
    get :index, {}, {:user => users(:testuser).id, :account_id => accounts(:app).id, :is_super_admin => users(:testuser).is_super_admin}
    assert_response :success
  end
  
  def test_not_super_admin
    get :index, {}, {:user => users(:demo).id, :account_id => accounts(:app).id, :is_super_admin => users(:demo).is_super_admin} 
    assert_redirected_to :controller => "home"
  end
  
  def test_page_contents
    get :index, {}, {:user => users(:testuser).id, :account_id => accounts(:app).id, :is_super_admin => users(:testuser).is_super_admin}
    assert_select "ul.list li", 5
    assert_select "ul.list li:first-child", :text => "6 Accounts - view or create"
    assert_select "ul.list li:nth-child(2)", :text => "7 Users - view or create"
    assert_select "ul.list li:nth-child(3)", :text => "7 Devices - view or create"
    assert_select "ul.list li:last-child", :text => "3 Device Profiles - view or create"
  end
end
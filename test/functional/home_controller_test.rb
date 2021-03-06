require 'test_helper'
require 'home_controller'


# Re-raise errors caught by the controller.
class HomeController; def rescue_action(e) raise e end; end

class HomeControllerTest < ActionController::TestCase
  
  fixtures :users, :accounts, :devices, :readings
  
  def setup
    @controller = HomeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    get :index, {}, {:user => users(:testuser), :account_id => accounts(:app).id}
    assert_response :success
  end
  
  def test_index_for_all
    get :index, {}, {:user => users(:testuser), :account_id => accounts(:app).id}, {:group_value => 'all'}
    assert_response :success    
    assert_equal 3 , assigns(:groups).length
  end
  
  def test_index_for_default
    get :index, {}, {:user => users(:testuser), :account_id => accounts(:app).id}, {:group_value => 'default'}
    assert_response :success    
    assert_equal 1 , assigns(:default_devices).length
  end

 def test_show_devices_all
     get :show_devices, {:group_type =>'all'}, {:user => users(:testuser), :account_id => accounts(:app).id}
     assert_redirected_to("action"=>"index")     
 end
 
  def test_show_devices_for_default
      get :show_devices,{:group_type =>'default'},{:user=>users(:testuser), :account_id => accounts(:app).id}
      assert_redirected_to("action"=>"index")      
  end
  
  def test_show_devices_for_group
      get :show_devices,{:group_type =>2},{:user=>users(:testuser), :account_id => accounts(:app).id}
      assert_redirected_to("action"=>"index")      
  end
    
  def test_not_logged_in
    get :index
    assert_redirected_to :controller => "login"
    assert_equal flash[:message], "You're not currently logged in"
  end
  
  def test_map
    get :map, {}, {:user=>users(:testuser), :account_id => accounts(:app).id}
    assert_response :success
  end
  
end

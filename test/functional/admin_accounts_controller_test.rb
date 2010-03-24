require 'test_helper'
class Admin::AccountsControllerTest < ActionController::TestCase
  
  fixtures :users, :accounts

  def test_index
    get :index, {}, get_user
    assert_response :success
  end
  
  def test_accounts_table
    get :index, {}, get_user
    assert_select "table tr", 7
  end
  
  def test_new_account
    get :new, {}, get_user
    assert_response :success
  end
  
  def test_create_account_without_subdomain
    post :create, {:account => {:company => "New Co", :zip => 12345}}, get_user
    assert_equal flash[:error], "Please specify a subdomain<br />"
  end
  
  def test_create_account_with_duplicate_subdomain
    post :create, {:account => {:company => "New Co", :zip => 12345, :subdomain => "app"}}, get_user
    assert_equal flash[:error], "Please choose another subdomain; this one is already taken<br />"
  end
  
  def test_create_account_with_subdomain
    post :create, {:account => {:subdomain => "monkey", :company => "New Co", :zip => 12345}}, get_user
    assert_redirected_to :action => "index"
    assert_equal flash[:success], "monkey created successfully"
  end
  
  def test_edit_account
    get :edit, {:id => 4}, get_user
    assert_response :success
  end
  
  def test_update_account_without_zip
    post :update, {:id => 4, :account => {:subdomain => "newco", :company => "New Co"}}, get_user
    assert_redirected_to :action => "edit"
    assert_equal flash[:error], "Please specify your zip code<br />"
  end
  
  def test_update_account_with_zip
    post :update, {:id => 4, :account => {:subdomain => "newco", :company => "New Co", :zip => 12345}}, get_user
    assert_redirected_to :action => "index"
    assert_equal flash[:success], "newco updated successfully"
  end
  
  def test_delete_account
    post :destroy, {:id => 1}, get_user
    assert_redirected_to :action => "index"
    assert_equal flash[:success], "app deleted successfully"
  end
  
  def test_super_admin_can_access_across_subdomains
      get :subdomain_login, {:id=>4}, get_user
      assert_redirected_to("http://app4.test.host:80/login/admin_login")
  end

  def test_subdomain_login_account_not_present
      get :subdomain_login, {:id=>12545}, get_user
      assert_redirected_to :controller=>'/home', :action=>'index'
  end
  
  def test_standard_user_cannot_access_subdomain
      get :subdomain_login, {:id=>1}, get_standard_user
      assert_redirected_to :controller=>'home'
  end
  
  def get_standard_user
     {:user => users(:demo).id, :account_id => users(:demo).id, :is_super_admin => users(:demo).is_super_admin} 
  end

  def get_user
    {:user => users(:testuser).id, :account_id => accounts(:app).id, :is_super_admin => users(:testuser).is_super_admin}
  end

end

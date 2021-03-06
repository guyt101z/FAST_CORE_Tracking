require 'test_helper'

class Admin::UsersControllerTest < ActionController::TestCase

  fixtures :users, :accounts

  def test_index
    get :index, {}, get_user
    assert_response :success
  end

  def test_users_table
    get :index, {}, get_user
    assert_select "table tr", 8
  end

  def test_new_user
    get :new, {}, get_user
    assert_response :success
  end

  def test_create_user_without_email
    post :create, {:user => {:first_name => "dennis", :last_name => "baldwin", :password => "helloworld", :password_confirmation => "helloworld", :account_id => 1}}, get_user
    assert_redirected_to :action => "new"
    assert_equal flash[:error], "Email can't be blank<br />"
  end

  def test_create_user_with_short_password
    post :create, {:user => {:first_name => "dennis", :last_name => "baldwin", :email => "dennisb@ublip.com", :password => "hello", :password_confirmation => "hello", :account_id => 1}}, get_user
    assert_redirected_to :action => "new"
    assert_equal flash[:error], "Password is too short (minimum is 6 characters)<br />"
  end

  def test_create_user_duplicate_email
    post :create, {:user => {:first_name => "test", :last_name => "user", :email => "testuser@ublip.com", :password => "helloworld", :password_confirmation => "helloworld", :account_id => 1}}, get_user
    assert_redirected_to :action => "new"
    assert_equal flash[:error], "Email has already been taken<br />"
  end

  def test_create_user
    post :create, {:user => {:first_name => "dennis", :last_name => "baldwin", :email => "dennisb@ublip.com", :password => "helloworld", :password_confirmation => "helloworld", :account_id => 1}}, get_user
    assert_redirected_to :action => "index"
    assert_equal flash[:success], "dennisb@ublip.com was created successfully"
  end

  def test_edit_account
    get :edit, {:id => 1}, get_user
    assert_response :success
  end

  def test_update_user
    post :update, {:id => 1, :user =>{:first_name => "dennis_new", :last_name => "baldwin_new", :email => "dennis@ublip.com", :account_id => 1}}, get_user
    assert_redirected_to :action => "index"
    assert_equal flash[:success], "dennis@ublip.com updated successfully"
  end

  def test_delete_user
    post :destroy, {:id => 1}, get_user
    assert_redirected_to :action => "index"
    assert_equal flash[:success], "testuser@ublip.com deleted successfully"
  end

  def get_user
    {:user => users(:testuser).id, :account_id => accounts(:app).id, :is_super_admin => users(:testuser).is_super_admin}
  end

end

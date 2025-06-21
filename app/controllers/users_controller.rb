class UsersController < ApplicationController
  before_action :require_login, only: [ :show ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      session[:user_id] = @user.id
      redirect_to dashboard_path, notice: "Welcome, #{@user.display_name}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @user = current_user
  end

  private

  def user_params
    params.expect(user: [ :username, :display_name, :email, :password, :password_confirmation ])
  end

  def require_login
    unless logged_in?
      redirect_to root_path, alert: "You must be logged in to view your profile."
    end
  end
end

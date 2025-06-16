class SessionsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(session_params)
    if @user.username.blank? || @user.password.blank?
      @user.errors.add(:username, "can't be blank") if @user.username.blank?
      @user.errors.add(:password, "can't be blank") if @user.password.blank?
      render :new, status: :unprocessable_entity
      return
    end
    user = User.find_by(username: @user.username)
    if user&.authenticate(@user.password)
      session[:user_id] = user.id
      redirect_to profile_path, notice: "Welcome, #{user.display_name}"
    else
      flash.now[:alert] = "Invalid username or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "You have been logged out."
  end

  private

  def session_params
    params.expect(user: [ :username, :password ])
  end
end

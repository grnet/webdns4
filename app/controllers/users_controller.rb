class UsersController < ApplicationController
  before_action :authenticate_user!

  before_action :user, only: [:token, :generate_token]

  # GET /users/1/token
  def token
  end

  # POST /users/1/generate_token
  def generate_token
    @user.token = SecureRandom.hex(10)
    @user.save!

    redirect_to token_user_path(@user)
  end

  private

  def user
    @user ||= User.find(params[:id])
  end

end

class UsersController < ApplicationController
  before_action :authenticate_user!

  before_action :user, only: [:mute, :unmute, :token, :generate_token]

  # GET /users/1/token
  def token
  end

  # POST /users/1/generate_token
  def generate_token
    @user.token = SecureRandom.hex(10)
    @user.save!

    redirect_to token_user_path(@user)
  end

  # PUT /users/1/unsubscribe/2
  def mute
    domain = show_domain_scope.find(params[:domain_id])
    @user.subscriptions.find_or_create_by!(domain: domain)

    redirect_to domains_url, notice: "Successfully unsubscribed from #{domain.name} notifications!"
  end

  # PUT /users/1/subscribe/2
  def unmute
    domain = show_domain_scope.find(params[:domain_id])
    # Drop all opt-outs
    @user.subscriptions.where(domain: domain).delete_all

    redirect_to domains_url, notice: "Successfully subscribed to #{domain.name} notifications!"
  end

  private

  def user
    @user ||= User.find(params[:user_id] || params[:id])

    # Guard access to other user tokens
    if current_user.id != @user.id && !admin?
      redirect_to(root_path, alert: 'You need admin rights for that!')
    end

    @user
  end

end

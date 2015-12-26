class GroupsController < ApplicationController
  before_action :authenticate_user!

  before_action :group, only: [:show, :create_member, :destroy_member, :search_member]
  before_action :user, only: [:destroy_member]

  # GET /groups/1
  def show
    @domains = @group.domains
  end

  # POST /groups/1/members/
  def create_member
    @user = User.find_by_email!(params[:email])
    membership = @group.memberships.find_or_create_by!(user_id: @user.id)

    redirect_to @group, notice: "#{membership.user.email} is now a member of #{@group.name}"
  end

  # DELETE /groups/1/member/1
  def destroy_member
    membership = @group.memberships.find_by!(user_id: user.id)
    membership.destroy!

    redirect_to @group, notice: "#{membership.user.email} was successfully removed from #{@group.name}"
  end

  def search_member
    results = []

    if params[:q].present?
      uids = group.users.pluck(:id)
      results = User
                .where('email like ?', "#{params[:q]}%")
                .where.not(id: uids) # Exclude group members
                .limit(10)
    end

    render json: results.map { |r| Hash[:id, r.id, :email, r.email] }
  end

  private

  def user
    @user ||= User.find(params[:user_id])
  end

end

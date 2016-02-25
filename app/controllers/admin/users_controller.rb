module Admin
  class UsersController < ApplicationController
    before_action :authenticate_user!
    before_action :admin_only!

    # GET /users/orphans
    def orphans
      @users = User.orphans
    end

    # DELETE /users/:id
    def destroy
      @user = User.find(params[:id])
      @user.destroy
      redirect_to orphans_admin_users_path, notice: "#{@user.email} was deleted."
    end

    def update_groups
      additions = 0

      params.each_pair { |k, group_id|
        next if !k.start_with?('orphan-')

        _, id = k.split('-', 2)
        user = User.orphans.find_by_id(id)
        next if !user

        group = Group.find_by_id(group_id)
        next if !group

        user.groups << group
        additions += 1
      }

      redirect_to :back, notice: "#{additions} users were assigned to groups"
    end

  end
end

module Admin
  class GroupsController < ApplicationController
    before_action :authenticate_user!
    before_action :admin_only!

    before_action :group, only: [:edit, :update, :destroy]

    # GET /groups
    def index
      @groups = Group.all
      @membership_count = Membership.group(:group_id).count
      @domain_count = Domain.group(:group_id).count
    end

    # GET /groups/new
    def new
      @group = Group.new
    end

    # GET /groups/1/edit
    def edit
    end

    # POST /groups
    def create
      @group = Group.new(group_params)

      if @group.save
        redirect_to @group, notice: "#{@group.name} was successfully created."
      else
        render :new
      end
    end

    # PATCH/PUT /groups/1
    def update
      if @group.update(group_params)
        redirect_to admin_groups_url, notice: "#{@group.name} was successfully updated."
      else
        render :edit
      end
    end

    # DELETE /groups/1
    def destroy
      @group.destroy
      redirect_to admin_groups_url, notice: "#{@group.name} was successfully destroyed."
    end

    private

    def group_params
      params.require(:group).permit(:name)
    end
  end
end

module Admin
  class JobsController < ApplicationController
    before_action :authenticate_user!
    before_action :admin_only!

    # GET /jobs
    def index
      @pending = Job.pending
      @completed = Job.completed.order('id desc')
    end

    # DELETE /jobs/1
    def destroy
      @job = Job.find(params[:id])
      @job.destroy
      redirect_to admin_jobs_url, notice: "#{@job.id} was successfully destroyed."
    end

  end
end

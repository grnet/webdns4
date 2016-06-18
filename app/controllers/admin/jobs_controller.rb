module Admin
  class JobsController < ApplicationController
    before_action :authenticate_user!
    before_action :admin_only!

    before_action :job, only: [:destroy, :update]

    # GET /jobs
    def index
      @job_categories = {
        'Pending' => Job.includes(:domain).pending,
        'Completed' => Job.includes(:domain).completed.order('id desc')
      }

      @category = params[:category] || 'pending'
    end

    # DELETE /jobs/1
    def destroy
      @job.destroy
      redirect_to admin_jobs_url, notice: "#{@job.id} was successfully destroyed."
    end

    # PUT /jobs/1
    def update
      if @job.update(job_params)
        redirect_to admin_jobs_url, notice: 'Job was successfully updated.'
      else
        render :edit
      end
    end

    private

    def job
      @job = Job.find(params[:id])
    end

    def job_params
      params.require(:job).permit(:status)
    end
  end
end

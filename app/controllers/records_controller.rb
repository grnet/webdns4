class RecordsController < ApplicationController
  before_action :set_domain
  before_action :set_record, only: [:edit, :update, :destroy]

  # GET /records/new
  def new
    @record = @domain.records.build
  end

  # GET /records/1/edit
  def edit
  end

  # POST /records
  def create
    @record = @domain.records.new(new_record_params)

    if @record.save
      redirect_to @domain, notice: 'Record was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /records/1
  def update
    if @record.update(edit_record_params)
      redirect_to @domain, notice: 'Record was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /records/1
  def destroy
    @record.destroy
    redirect_to @domain, notice: 'Record was successfully destroyed.'
  end

  private
  def set_record
    @record = @domain.records.find(params[:id])
  end

  def set_domain
    @domain = Domain.find(params[:domain_id])
  end

  def edit_record_params
    params.require(:record).permit(:name, :content, :prio, :disabled)
  end

  def new_record_params
    params.require(:record).permit(:name, :content, :type, :prio)
  end
end

class RecordsController < ApplicationController
  before_action :authenticate_user!

  before_action :domain, except: [:search]
  before_action :editable_transform_params, only: [:editable]
  before_action :record, only: [:edit, :update, :editable, :destroy]

  # GET /records/new
  def new
    @record = domain.records.build
  end

  # GET /records/1/edit
  def edit
  end

  # POST /records
  def create
    @record = domain.records.new(new_record_params)

    if @record.save
      notify_record(@record, :create)
      redirect_to domain, notice: 'Record was successfully created.'
    else
      flash[:alert] = 'There were some errors creating the record!'
      render :new
    end
  end

  # PATCH/PUT /records/1
  def update
    if @record.update(edit_record_params)
      notify_record(@record, :update)
      redirect_to domain, notice: 'Record was successfully updated.'
    else
      render :edit
    end
  end

  def editable
    if @record.update(edit_record_params)
      notify_record(@record, :update)
      response = {
        value: @record.read_attribute(@attr),
        serial: @domain.soa(true).serial,
        record: @record.as_json
      }

      render json: response
    else
      render text: @record.errors[@attr].join(', '), status: 400
    end
  end

  # DELETE /records/1
  def destroy
    @record.destroy
    notify_record(@record, :destroy)
    redirect_to domain, notice: 'Record was successfully destroyed.'
  end

  # GET /search
  def search
    @records = Record
               .where(domain: show_domain_scope)
               .includes(:domain)
               .search(params[:q]) # scope by domain

    @records = Record.smart_order(@records)
  end

  private

  # Modify params to use standard Rails patterns
  def editable_transform_params
    @attr = params[:name]
    params[:record] = { params[:name] => params[:value] }
  end

  def edit_record_params
    if @record.type == 'SOA'
      permitted = [:contact, :serial, :refresh, :retry, :expire, :nx]
    else
      permitted = [:name, :content, :ttl, :prio, :disabled]
    end

    params.require(:record).permit(*permitted).tap { |r|
      r[:drop_privileges] = true if not admin?
    }
  end

  def new_record_params
    params.require(:record).permit(:name, :content, :ttl, :type, :prio).tap { |r|
      r[:drop_privileges] = true if not admin?
    }
  end

  def notify_record(*args)
    notification.notify_record(current_user, *args) if WebDNS.settings[:notifications]
  end
end

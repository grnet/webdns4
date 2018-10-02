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
    session[:edit_record_redirect_to] = request.referrer
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

      ret = session[:edit_record_redirect_to] ? session.delete(:edit_record_redirect_to) : domain

      redirect_to ret, notice: 'Record was successfully updated.'
    else
      render :edit
    end
  end

  def valid
    @record = domain.records.new(new_record_params)
    if @record.valid?
      response = {
        record: @record.as_bulky_json,
        errors: false
      }

      render json: response
    else
      render json: { errors: @record.errors.full_messages.join(', ') }
    end
  end

  def bulk
    ops, err = @domain.bulk(params)
    if err.empty?
      notify_record_bulk(@domain, ops)
      render json: { ok: true }
    else
      render json: { errors: err }
    end
  end

  def editable
    @record.assign_attributes(edit_record_params)

    if @record.valid?
      if @save
        @record.save!
        notify_record(@record, :update)
      end

      response = {
        attribute: @attr,
        value: @record.read_attribute(@attr),
        serial: @domain.soa(true).serial,
        record: @record.as_bulky_json,
        saved: @save
      }

      render json: response
    else
      render text: @record.errors[@attr].join(', '), status: 400
    end
  end

  # DELETE /records/1
  def destroy
    ret = request.referrer
    if @record.type == 'SOA'
      redirect_to ret, alert: 'SOA records cannot be deleted!'
      return
    end

    @record.destroy
    notify_record(@record, :destroy)
    redirect_to ret, notice: 'Record was successfully destroyed.'
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
    @save = params[:save] != 'false'
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

  def notify_record_bulk(*args)
    notification.notify_record_bulk(current_user, *args) if WebDNS.settings[:notifications]
  end
end

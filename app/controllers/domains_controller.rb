class DomainsController < ApplicationController
  before_action :authenticate_user!

  before_action :domain, only: [:show, :edit, :edit_dnssec, :update, :destroy]
  before_action :group,  only: [:show, :edit, :edit_dnssec, :update, :destroy]

  helper_method :edit_group_scope

  # GET /domains
  def index
    @domains = show_domain_scope.all
  end

  # GET /domains/1
  def show
    @record = Record.new(domain_id: @domain.id)
  end

  # GET /domains/new
  def new
    @domain = Domain.new(new_domain_params)
  end

  # GET /domains/1/edit
  def edit
  end

  # GET /domains/1/edit_dnssec
  def edit_dnssec
  end

  # POST /domains
  def create
    @domain = Domain.new(domain_params)

    if @domain.save
      notify_domain(@domain, :create)
      redirect_to @domain, notice: "#{@domain.name} was successfully created."
    else
      render :new
    end
  end

  # PATCH/PUT /domains/1
  def update
    if @domain.update(domain_params)
      notify_domain(@domain, :update)
      redirect_to @domain, notice: "#{@domain.name} was successfully updated."
    else
      if domain_params[:dnssec] # DNSSEC form
        render :edit_dnssec
      else
        render :edit
      end
    end
  end

  # DELETE /domains/1
  def destroy
    @domain.destroy
    notify_domain(@domain, :destroy)
    redirect_to domains_url, notice: "#{@domain.name} was successfully destroyed."
  end

  private

  def group
    domain.group
  end

  def new_domain_params
    params.permit(:group_id)
  end

  def domain_params
    params.require(:domain).tap { |d|
      # Make sure group id is permitted (belongs to edit_group_scope)
      d[:group_id] = edit_group_scope.find_by_id(d[:group_id]).try(:id)
    }.permit(:name, :type, :master, :group_id, :dnssec, :dnssec_parent, :dnssec_parent_authority)
  end

  def notify_domain(*args)
    notification.notify_domain(current_user, *args)
  end

end

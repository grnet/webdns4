require 'set'

class DomainsController < ApplicationController
  before_action :authenticate_user!

  before_action :domain, only: [:show, :edit, :edit_dnssec, :update, :destroy, :full_destroy]
  before_action :group,  only: [:show, :edit, :edit_dnssec, :update, :destroy, :full_destroy]

  helper_method :edit_group_scope

  # GET /domains
  def index
    @domains = show_domain_scope.includes(:group, :soa).all
    @optouts = Set.new current_user.subscriptions.pluck(:domain_id)
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
      flash[:alert] = 'There were some errors creating the domain!'
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
    if @domain.remove
      notify_domain(@domain, :destroy)
      redirect_to domains_url, notice: "#{@domain.name} is scheduled for removal."
    else
      redirect_to domains_url, alert: "#{@domain.name} cannot be deleted! (state '#{@domain.state}')"
    end
  end

  # DELETE /domains/1/full_destroy
  def full_destroy
    if @domain.full_remove
      notify_domain(@domain, :destroy)
      redirect_to domains_url,
                  notice: "#{@domain.name} is scheduled for full removal. DS records will be dropped from the parent zone before proceeding"
    else
      redirect_to domains_url, alert: "#{@domain.name} cannot be deleted! (state '#{@domain.state}')"
    end
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
      # Sometimes domain name might contain whitespace, make sure we remove
      # them. Note that we use a regex to handle unicode whitespace characters as well.
      d[:name] = d[:name].gsub(/\p{Space}/, '') if d[:name]
    }.permit(:name, :type, :master, :group_id,
             :dnssec, :dnssec_parent, :dnssec_parent_authority, :dnssec_policy_id)
  end

  def notify_domain(*args)
    notification.notify_domain(current_user, *args) if WebDNS.settings[:notifications]
  end

end

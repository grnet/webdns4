class DomainsController < ApplicationController
  before_action :set_domain, only: [:show, :edit, :update, :destroy]

  # GET /domains
  def index
    @domains = Domain.all
  end

  # GET /domains/1
  def show
  end

  # GET /domains/new
  def new
    @domain = Domain.new
  end

  # GET /domains/1/edit
  def edit
  end

  # POST /domains
  def create
    @domain = Domain.new(domain_params)

    if @domain.save
      redirect_to @domain, notice: "#{@domain.name} was successfully created."
    else
      render :new
    end
  end

  # PATCH/PUT /domains/1
  def update
    if @domain.update(domain_params)
      redirect_to @domain, notice: "#{@domain.name} was successfully updated."
    else
      render :edit
    end
  end

  # DELETE /domains/1
  def destroy
    @domain.destroy
    redirect_to domains_url, notice: "#{@domain.name} was successfully destroyed."
  end

  private
  def set_domain
    @domain = Domain.find(params[:id])
  end

  def domain_params
    params.require(:domain).permit(:name, :type)
  end
end

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  attr_writer :breadcrumb
  helper_method :admin?

  def admin?
    params.key?(:admin)
  end

  private

  def group
    @group ||= group_scope.find(params[:group_id] || params[:id])
  end

  def domain
    @domain ||= domain_scope.find(params[:domain_id] || params[:id])
  end

  def record
    @record ||= record_scope.find(params[:record_id] || params[:id])
  end

  def group_scope
    @group_scope ||= current_user.groups
  end

  def domain_scope
    @domain_scope ||= Domain.where(group: group_scope)
  end

  def record_scope
    @record_scope ||= domain.records
  end

end

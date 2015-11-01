class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  attr_writer :breadcrumb

  private

  def group
    @group ||= domain.group
  end

  def domain
    @domain ||= domain_scope.find(params[:domain_id] || params[:id])
  end

  def record
    @record ||= record_scope.find(params[:record_id] || params[:id])
  end

  def group_scope
    @group_scope ||= Group.all
  end

  def domain_scope
    @domain_scope ||= Domain.where(group: group_scope)
  end

  def record_scope
    @record_scope ||= domain.records
  end

end

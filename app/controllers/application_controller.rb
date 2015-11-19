class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  attr_writer :breadcrumb
  helper_method :admin?

  def admin?
    return false if params.key?('user')
    return false if current_user.nil?

    @admin_count ||= begin
                       current_user
                       .groups
                       .where(name: WebDNS.settings[:admin_group]).count
                     end

    @admin_count != 0
  end

  def admin_only!
    return if admin?

    redirect_to root_path, alert: 'Admin only area!'
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
    @group_scope ||= admin? ? Group.all : current_user.groups
  end

  def domain_scope
    @domain_scope ||= admin? ? Domain.all : Domain.where(group: group_scope)
  end

  def record_scope
    @record_scope ||= domain.records
  end

end

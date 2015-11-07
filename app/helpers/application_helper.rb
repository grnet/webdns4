module ApplicationHelper
  def can_edit?(object)
    return true if admin?
    return true unless object.respond_to?(:editable?)

    object.editable?
  end
end

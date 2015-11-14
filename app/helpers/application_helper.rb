module ApplicationHelper
  def can_edit?(object)
    return true if admin?
    return true unless object.respond_to?(:editable?)

    object.editable?
  end

  def link_to_edit(*args, &block)
    link_to(abbr_glyph(:pencil, 'Edit'), *args, &block)
  end

  def link_to_destroy(*args, &block)
    link_to(abbr_glyph(:remove, 'Remove'), *args, &block)
  end

  def link_to_enable(*args, &block)
    link_to(abbr_glyph(:'eye-close', 'Enable'), *args, &block)
  end

  def link_to_disable(*args, &block)
    link_to(abbr_glyph(:'eye-open', 'Disable'), *args, &block)
  end

  def glyph(icon)
    content_tag(:span, '', class: "glyphicon glyphicon-#{icon}")
  end

  private

  def abbr_glyph(icon, title)
    content_tag(:abbr, glyph(icon), title: title)
  end

end

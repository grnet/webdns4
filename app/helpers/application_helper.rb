module ApplicationHelper
  TIME_PERIODS = {
    1.second => 'second',
    1.minute => 'minute',
    1.hour => 'hour',
    1.day => 'day',
    1.week => 'week',
    1.month => 'month',
    1.year.to_i => 'year',
  }

  def can_edit?(object)
    return true unless object.respond_to?(:editable?)
    by = admin? ? :admin : :user

    object.editable?(by)
  end

  def seconds_to_human(seconds)
    acc = {}
    remaining = seconds
    TIME_PERIODS.to_a.reverse_each do |p, human|
      period_count, remaining = remaining.divmod(p)
      acc[human] = period_count if not period_count.zero?
    end

    acc.map { |singular, count|
      human = count < 2 ? singular : "#{singular}s"
      "#{count} #{human}"
    }.join(', ')
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

  def abbr_glyph(icon, title)
    content_tag(:abbr, glyph(icon), title: title)
  end

end

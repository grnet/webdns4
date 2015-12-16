module BreadcrumbHelper
  # Domain
  # Domain / group / example.com
  # Domain / group / example.com / ns1.example.com IN A
  # Domain / group / example.com / new
  def breadcrumbs(leaf)
    crumbs = generate_crumbs_for(leaf)

    crumbs.each { |c|
      # Last element should not be a link
      if c == crumbs.last || c[:link].nil?
        yield c[:name]
      else
        yield link_to(c[:name], c[:link])
      end
    }
  end

  private

  # rubocop:disable all
  def generate_crumbs_for(leaf)
    stack = []
    crumbs = []
    stack.push leaf if leaf

    while crumb = stack.pop # rubocop:disable Lint/AssignmentInCondition
      case crumb
      when Record
        if crumb.persisted?
          crumbs.push(
            name: "#{crumb.name} IN #{crumb.type}",
            link: domain_record_path(crumb.domain_id, crumb))
        end
        stack.push crumb.domain
      when Domain
        if crumb.persisted?
          name = crumb.name.dup
          name += " (#{human_state(crumb.state)})" if crumb.state != 'operational'
          crumbs.push(name: name, link: domain_path(crumb))
        else
          crumbs.push(name: :new)
        end
        stack.push crumb.group
      when Group
        if crumb.persisted?
          crumbs.push(name: crumb.name, link: group_path(crumb))
        else
          crumbs.push(name: :new)
        end
      end
    end

    crumbs.push(name: glyph(:home), link: '/')

    crumbs.reverse
  end
  # rubocop:enable all

end

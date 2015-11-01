module BreadcrumbHelper
  # Domain
  # Domain / group / example.com
  # Domain / group / example.com / ns1.example.com IN A
  # Domain / group / example.com / new
  def breadcrumbs(leaf)
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
        else
          crumbs.push(name: :new)
        end
        stack.push crumb.domain
      when Domain
        if crumb.persisted?
          crumbs.push(name: crumb.name, link: domain_path(crumb))
        else
          crumbs.push(name: :new)
        end
        stack.push crumb.group
      when Group
        crumbs.push(name: crumb.name)
      end
    end

    crumbs.push(name: 'Domains', link: '/')

    crumbs.reverse!
    crumbs.each { |c|
      # Last element should not be a link
      if c == crumbs.last || c[:link].nil?
        yield c[:name]
      else
        yield link_to(c[:name], c[:link])
      end
    }
  end

end

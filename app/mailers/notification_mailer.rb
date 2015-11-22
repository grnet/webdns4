class NotificationMailer < ActionMailer::Base
  default from: WebDNS.settings[:mail_from]

  PREFIXES = {
    create: 'Created',
    update: 'Modified',
    destroy: 'Deleted',
  }

  def notify_record(record:, context:, user:, admin:, others:, changes:)
    @record = record
    @context = context
    @user = user
    @admin = admin
    @changes = changes

    mail(to: others, subject: "[webdns] [record] #{PREFIXES[context.to_sym]} #{record.to_short_dns}")
  end

  def notify_domain(domain:, context:, user:, admin:, others:, changes:)
    @domain = domain
    @context = context
    @user = user
    @admin = admin
    @changes = changes

    mail(to: others, subject: "[webdns] [domain] #{PREFIXES[context.to_sym]} #{domain.name}")
  end
end

class NotificationMailer < ActionMailer::Base
  default from: WebDNS.settings[:mail_from]

  ENVIRON_PREFIX = WebDNS.settings[:notifications_prefix] || 'webdns'

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

    mail(to: others, subject: "[#{ENVIRON_PREFIX}] [record] #{PREFIXES[context.to_sym]} #{record.to_short_dns}")
  end

  def notify_record_bulk(domain:, user:, admin:, others:, operations:)
    @domain = domain
    @user = user
    @admin = admin
    @operations = operations

    mail(to: others, subject: "[#{ENVIRON_PREFIX}] [record] Bulk operations for '#{domain.name}'")
  end

  def notify_domain(domain:, context:, user:, admin:, others:, changes:)
    @domain = domain
    @context = context
    @user = user
    @admin = admin
    @changes = changes

    mail(to: others, subject: "[#{ENVIRON_PREFIX}] [domain] #{PREFIXES[context.to_sym]} #{domain.name}")
  end

end

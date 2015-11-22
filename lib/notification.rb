require 'singleton'

class Notification
  include Singleton

  # Send out a notification about notable record changes
  def notify_record(user, record, context)
    ActiveSupport::Notifications.instrument(
      'webdns.record',
      user: user,
      context: context,
      object: record)
  end

  # Send out a notification about notable domain changes
  def notify_domain(user, domain, context)
    ActiveSupport::Notifications.instrument(
      'webdns.domain',
      user: user,
      context: context,
      object: domain)
  end

  # Subscribe to domain/record notifications
  def hook
    hook_record
    hook_domain
  end

  private

  def hook_record
    ActiveSupport::Notifications
      .subscribe 'webdns.record' do |_name, _started, _finished, _unique_id, data|
      handle_record(data)
    end
  end

  def hook_domain
    ActiveSupport::Notifications
      .subscribe 'webdns.domain' do |_name, _started, _finished, _unique_id, data|
      handle_domain(data)
    end
  end

  def handle_record(data) # rubocop:disable Metrics/MethodLength
    record, context, user = data.values_at(:object, :context, :user)
    domain = record.domain
    changes = record.previous_changes

    # Nobody is interested in those
    changes.delete('updated_at')
    changes.delete('created_at')
    return if changes.empty?

    others = domain.group.users.where.not(id: user.id).pluck(:email)
    return if others.empty?

    admin_action = !user.groups.exists?(domain.group_id)

    NotificationMailer.notify_record(
      record: record,
      context: context,
      user: user,
      admin: admin_action,
      others: others,
      changes: changes
    ).deliver
  end

  def handle_domain(data) # rubocop:disable Metrics/MethodLength
    domain, context, user = data.values_at(:object, :context, :user)
    changes = domain.previous_changes

    # Nobody is interested in those
    changes.delete('updated_at')
    changes.delete('created_at')
    return if changes.empty?

    others = domain.group.users.where.not(id: user.id).pluck(:email)
    return if others.empty?

    admin_action = !user.groups.exists?(domain.group_id)
    NotificationMailer.notify_domain(
      domain: domain,
      context: context,
      user: user,
      admin: admin_action,
      others: others,
      changes: changes
    ).deliver
  end
end

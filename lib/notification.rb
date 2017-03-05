require 'singleton'

class Notification
  include Singleton

  # Send out a notification about bulk record operations.
  def notify_record_bulk(user, domain, ops)
    ActiveSupport::Notifications.instrument(
      'webdns.record.bulk',
      user: user,
      domain: domain,
      ops: ops)
  end

  # Send out a notification about notable record changes.
  def notify_record(user, record, context)
    ActiveSupport::Notifications.instrument(
      'webdns.record',
      user: user,
      context: context,
      object: record)
  end

  # Send out a notification about notable domain changes.
  def notify_domain(user, domain, context)
    ActiveSupport::Notifications.instrument(
      'webdns.domain',
      user: user,
      context: context,
      object: domain)
  end

  # Subscribe to domain/record notifications.
  def hook
    hook_record
    hook_record_bulk
    hook_domain
  end

  private

  def hook_record
    ActiveSupport::Notifications
      .subscribe 'webdns.record' do |_name, _started, _finished, _unique_id, data|
      handle_record(data)
    end
  end

  def hook_record_bulk
    ActiveSupport::Notifications
      .subscribe 'webdns.record.bulk' do |_name, _started, _finished, _unique_id, data|
      handle_record_bulk(data)
    end
  end

  def hook_domain
    ActiveSupport::Notifications
      .subscribe 'webdns.domain' do |_name, _started, _finished, _unique_id, data|
      handle_domain(data)
    end
  end

  def handle_record(data)
    record, context, user = data.values_at(:object, :context, :user)
    domain = record.domain

    changes = filter_changes(record)
    return if changes.empty? && context == :update

    others = domain.group.users.pluck(:email)
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

  def handle_record_bulk(data)
    ops, domain, user = data.values_at(:ops, :domain, :user)

    operations = []
    operations += ops[:deletes].map   { |rec| [:destroy, rec, nil] }
    operations += ops[:changes].map   { |rec| [:update, rec, filter_changes(rec)] }
    operations += ops[:additions].map { |rec| [:create, rec, nil] }

    others = domain.group.users.pluck(:email)
    return if others.empty?

    admin_action = !user.groups.exists?(domain.group_id)

    NotificationMailer.notify_record_bulk(
      user: user,
      admin: admin_action,
      others: others,
      domain: domain,
      operations: operations,
    ).deliver
  end

  def handle_domain(data)
    domain, context, user = data.values_at(:object, :context, :user)

    changes = filter_changes(domain)
    return if changes.empty? && context == :update

    others = domain.group.users.pluck(:email)
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

  private

  def filter_changes(record)
    changes = record.previous_changes

    # Nobody is interested in those
    changes.delete('updated_at')
    changes.delete('created_at')

    changes
  end

end

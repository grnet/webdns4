require 'test_helper'

class NotificationMailerTest < ActionMailer::TestCase

  class DomainNotificationMailerTest < ActionMailer::TestCase
    def setup
      @notification = Notification.instance

      @group = create(:group_with_users)
      @domain = create(:domain, group: @group)
      @record = build(:a, name: 'a', domain: @domain)
    end

    test 'domain add' do
      @record.save!

      @notification.notify_domain(@group.users.first, @domain, :create)

      assert_not ActionMailer::Base.deliveries.empty?
      mail = ActionMailer::Base.deliveries.last

      assert_equal [@group.users.last.email], mail.to
      assert_includes mail.subject, 'Created'
      assert_includes mail.body.to_s, "Domain: #{@domain.name}"
      assert_includes mail.body.to_s, "By: #{@group.users.first.email}"
    end

    test 'domain edit' do
      @record.save!

      @domain.type = 'SLAVE'
      @domain.master = '1.2.3.4'
      @domain.save!

      @notification.notify_domain(@group.users.first, @domain, :update)

      assert_not ActionMailer::Base.deliveries.empty?
      mail = ActionMailer::Base.deliveries.last

      assert_equal [@group.users.last.email], mail.to
      assert_includes mail.subject, 'Modified'
      assert_includes mail.body.to_s, "Domain: #{@domain.name}"
      assert_includes mail.body.to_s, "By: #{@group.users.first.email}"
      assert_includes mail.body.to_s, 'type from NATIVE'
      assert_includes mail.body.to_s, 'type to   SLAVE'
      assert_includes mail.body.to_s, 'master from (empty)'
      assert_includes mail.body.to_s, 'master to   1.2.3.4'
    end

    test 'domain destroy' do
      @record.save!

      @domain.destroy!

      @notification.notify_domain(@group.users.first, @domain, :destroy)

      assert_not ActionMailer::Base.deliveries.empty?
      mail = ActionMailer::Base.deliveries.last

      assert_equal [@group.users.last.email], mail.to
      assert_includes mail.subject, 'Deleted'
      assert_includes mail.body.to_s, "Domain: #{@domain.name}"
      assert_includes mail.body.to_s, "By: #{@group.users.first.email}"
    end
  end

  class DomainNotificationMailerTest < ActionMailer::TestCase
    test 'record add' do
      @record.save!

      @notification.notify_record(@group.users.first, @record, :create)

      assert_not ActionMailer::Base.deliveries.empty?
      mail = ActionMailer::Base.deliveries.last

      assert_equal [@group.users.last.email], mail.to
      assert_includes mail.subject, 'Created'
      assert_includes mail.body.to_s, "Record: #{@record.name}"
      assert_includes mail.body.to_s, "Domain: #{@domain.name}"
      assert_includes mail.body.to_s, "State: #{@record.to_dns}"
      assert_includes mail.body.to_s, "By: #{@group.users.first.email}"
    end

    test 'record edit' do
      @record.save!

      prev_content = @record.content
      @record.content = '1.1.1.1'
      @record.save!

      @notification.notify_record(@group.users.first, @record, :update)

      assert_not ActionMailer::Base.deliveries.empty?
      mail = ActionMailer::Base.deliveries.last

      assert_equal [@group.users.last.email], mail.to
      assert_includes mail.subject, 'Modified'
      assert_includes mail.body.to_s, "Record: #{@record.name}"
      assert_includes mail.body.to_s, "Domain: #{@domain.name}"
      assert_includes mail.body.to_s, "State: #{@record.to_dns}"
      assert_includes mail.body.to_s, "By: #{@group.users.first.email}"
      assert_includes mail.body.to_s, "content from #{prev_content}"
      assert_includes mail.body.to_s, 'content to   1.1.1.1'
    end

    test 'soa edit' do
      @record = @domain.soa

      prev_content = @record.content
      @record.nx = 10
      @record.save!

      @notification.notify_record(@group.users.first, @record, :update)

      assert_not ActionMailer::Base.deliveries.empty?
      mail = ActionMailer::Base.deliveries.last

      assert_equal [@group.users.last.email], mail.to
      assert_includes mail.subject, 'Modified'
      assert_includes mail.body.to_s, "Record: #{@record.name}"
      assert_includes mail.body.to_s, "Domain: #{@domain.name}"
      assert_includes mail.body.to_s, "State: #{@record.to_dns}"
      assert_includes mail.body.to_s, "By: #{@group.users.first.email}"
      assert_includes mail.body.to_s, "content from #{prev_content}"
      assert_includes mail.body.to_s, "content to   #{@record.content}"
      assert_includes mail.body.to_s, ' 10'
    end

    test 'record destroy' do
      @record.save!

      @record.destroy!

      @notification.notify_record(@group.users.first, @record, :destroy)

      assert_not ActionMailer::Base.deliveries.empty?
      mail = ActionMailer::Base.deliveries.last

      assert_equal [@group.users.last.email], mail.to
      assert_includes mail.subject, 'Deleted'
      assert_includes mail.body.to_s, "Record: #{@record.name}"
      assert_includes mail.body.to_s, "Domain: #{@domain.name}"
      assert_includes mail.body.to_s, "By: #{@group.users.first.email}"
    end
  end
end

class Job < ActiveRecord::Base
  belongs_to :domain

  scope :pending, -> { where(status: 0) }
  scope :completed, -> { where(status: [1, 2]) }

  def failed?
    status == 2
  end

  class << self
    def add_domain(domain)
      ActiveRecord::Base.transaction do
        jobs_for_domain(domain, :add_domain)

        trigger_event(domain, :installed)
      end
    end

    def remove_domain(domain)
      ActiveRecord::Base.transaction do
        jobs_for_domain(domain, :remove_domain)

        trigger_event(domain, :cleaned_up)
      end
    end

    def dnssec_sign(domain)
      ActiveRecord::Base.transaction do
        jobs_for_domain(domain,
                        :opendnssec_add,
                        :bind_convert_to_dnssec)

        trigger_event(domain, :signed)
      end
    end

    def wait_for_ready(domain)
      jobs_for_domain(domain,
                      :wait_for_ready_to_push_ds)
    end

    def dnssec_push_ds(domain, dss)
      ActiveRecord::Base.transaction do
        job_for_domain(domain, :publish_ds, dss: dss)
        job_for_domain(domain, :wait_for_active)

        trigger_event(domain, :converted)
      end
    end

    def convert_to_plain(domain)
      ActiveRecord::Base.transaction do
        jobs_for_domain(domain,
                        :remove_domain,
                        :add_domain,
                        :opendnssec_remove)

        trigger_event(domain, :converted)
      end
    end

    private

    def trigger_event(domain, event)
      job_for_domain(domain, :trigger_event, event: event)
    end

    def jobs_for_domain(domain, *job_names)
      job_names.each { |job_name| job_for_domain(domain, job_name) }
    end

    def job_for_domain(domain, job_name, args = {})
      args = { zone: domain.name }.merge!(args)

      create!(domain: domain, job_type: job_name, args: args.to_json)
    end

  end

end

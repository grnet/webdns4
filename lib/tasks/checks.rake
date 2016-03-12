namespace :check do
  desc "Find Failing jobs"
  task failed_jobs: :environment do
    failed = Job.failed.order('id asc').to_a

    if failed.any?
      domains = failed.map { |j|
        j.domain ? "#{j.domain_id}:#{j.zone}" : "nodb:#{j.zone}"
      }
      domains = domains[0,3].join(', ') # Output only the first 3 domains
      puts "1 FailedJobs - WARN - #{failed.size} failed jobs on #{domains.size} domains (#{domains}...)"
    else
      puts "0 FailedJobs - OK - 0 failed jobs"
    end
  end
end

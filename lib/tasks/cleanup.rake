namespace :cleanup do
  desc "Cleanup completed jobs"
  task :jobs => :environment do
    count = Job.completed.count - WebDNS.settings[:completed_jobs_count]
    count = count < 0 ? 0 : count
    puts "Will remove %s jobs" % count
    Job.completed.order(created_at: :desc).limit(count).destroy_all
    puts "Done"
  end

  # add new jobs here too
  task :all => [:jobs]
end

desc "Cleanup everything"
task :cleanup => 'cleanup:all'

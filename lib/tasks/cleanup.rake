namespace :cleanup do
  desc "Cleanup completed jobs"
  task :jobs => :environment do
    Job.completed.destroy_all
  end

  # add new jobs here too
  task :all => [:jobs]
end

desc "Cleanup everything"
task :cleanup => 'cleanup:all'

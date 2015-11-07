namespace :bean do
  desc 'Start beanstalk worker'
  task work: :environment do
    Bean::Worker.work
  end
end

set :application, 'carbon-diet'

set :scm, "git"
set :repository, 'git@github.com:Floppy/carbon-diet.git'
set :deploy_via, :export

set :deploy_to, '/home/carbondiet'
set :user, 'carbondiet'

role :app, 'www.carbondiet.org'
role :web, 'www.carbondiet.org'
role :db,  'www.carbondiet.org', :primary => true

after "deploy:update_code", "symlink:avatars", "copy:dbconfig", "copy:hoptoad"

after "deploy", "deploy:cleanup"

namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end
  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end
end

namespace :symlink do
  desc "Symlink the avatars folder."
  task :avatars do
    run "ln -fs #{shared_path}/avatars #{release_path}/public/images"
  end
end

namespace :copy do
  desc "Make copy of database yaml" 
  task :dbconfig do
    run "cp #{shared_path}/config/database.yml #{release_path}/config/database.yml" 
  end
  desc "Make copy of hoptoad yaml"
  task :hoptoad do
    run "cp #{shared_path}/config/hoptoad.yml #{release_path}/config/hoptoad.yml"
  end
end

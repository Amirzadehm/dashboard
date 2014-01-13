require 'bundler/capistrano'

set :application, "dashboard"
set :user, "ubuntu"
set :use_sudo, false
set :stages, ["staging", "production", "private"]
#set :default_stage, "staging"

set :scm, "git"
set :branch, "master"
set :repository,  "https://github.com/code-dot-org/dashboard.git"
#set :git_enable_submodules, 1

set :keep_releases, 10
set :deploy_to, "/home/#{user}/apps/#{application}"

require 'capistrano/ext/multistage'

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} unicorn server"
    task command, roles: :app, except: {no_release: true} do
      run "/etc/init.d/unicorn #{command}"
    end
  end

  task :post_deploy do
    rake = fetch(:rake, 'rake')
    rails_env = fetch(:rails_env, 'development')

    run "cd '#{current_path}' && #{rake} blockly:latest pseudolocalize RAILS_ENV=#{rails_env}"
  end

  task :setup_config, roles: :app do
    run "export RAILS_ENV=#{rails_env}"
    sudo "#{current_path}/server_setup.sh #{current_path} #{user} #{rails_env}"
  end
  before "deploy:restart", "deploy:setup_config"

  task :symlink_config, roles: :app do
    #run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/application.yml #{release_path}/config/application.yml"
    run "ln -nfs #{shared_path}/config/unicorn.rb #{release_path}/config/unicorn.rb"
  end

  after "deploy:finalize_update", "deploy:symlink_config"

  desc "Make sure local git is in sync with remote."
  task :check_revision, roles: :web do
    unless `git rev-parse HEAD` == `git rev-parse origin/master`
      puts "WARNING: HEAD is not the same as origin/master"
      puts "Run `git push` to sync changes."
      exit
    end
  end

  task :perms do
    csrc = "#{shared_path}/c"
    cdst = "#{latest_release}/public/c"

    run <<-CMD
     if [ ! -d #{csrc} ] ; then mkdir -p #{csrc} ; fi &&
     if [ ! -e #{cdst} ] ; then ln -s #{csrc} #{cdst} ; fi
    CMD
  end

  task :directory_structure do
    run "mkdir -p ~/apps/dashboard/releases"
  end

  task :install_git do
    run "which git ; if [ $? -eq 1] ; then run sudo aptitude -y install git ; fi"
  end

  task :shared_config do
    run "mkdir -p #{shared_path}/config"
  end

  after "deploy:finalize_update", "deploy:perms"
  after "deploy:create_symlink", "deploy:post_deploy"
  before "deploy", "deploy:check_revision"
  after "deploy:update", "deploy:cleanup"
  after "deploy:setup", "deploy:shared_config"
end

require './config/boot'
require 'honeybadger/capistrano'

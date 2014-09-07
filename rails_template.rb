
def run_inner(command)
    run "bash -lc \"rvm use #{@ruby_version}@#{@app_name}; #{command}\""
end

dir = Dir::pwd

########################################
# rvm
########################################
@ruby_version = ask("which version of ruby do you use")
# run "source ~/.rvm/scripts/rvm"
run "bash -lc \"rvm use #{@ruby_version}; rvm gemset create #{@app_name}; gem update bundler;\""

########################################
# Gemfile
########################################
remove_file 'Gemfile'
create_file 'Gemfile' do body = '' end

add_source 'https://rubygems.org'
add_source 'https://rails-assets.org'

gem 'rails'
gem 'rake'

gem_group :development do 
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'bullet'
  gem 'rack-mini-profiler'
  gem 'hirb'
  gem 'hirb-unicode'
  gem 'puma'
end

gem_group :production, :staging do
  gem 'mysql2'
  gem 'unicorn'
  gem 'rails_12factor'
end

gem_group :development, :test do
  gem 'style-guide'
  gem "rack-livereload"
  gem "guard-livereload"
  gem 'pry-rails'
  gem 'pry-doc'
  gem 'pry-coolline'
  gem 'pry-byebug'
  gem 'sqlite3'
  gem 'sqlite3-ruby', :require => 'sqlite3'
  gem 'factory_girl', '4.0'
  gem 'factory_girl_rails'
  gem 'rspec-rails'
  gem "simplecov", require: false
  gem 'capybara'  
  gem "capybara-webkit"
  gem 'poltergeist'
  gem 'launchy'
  gem 'spring'
  gem 'guard-rspec'
  gem 'guard-spring'
  gem 'terminal-notifier-guard'
  gem 'childprocess'
  gem 'database_cleaner'
  # gem 'rake_shared_context'

  gem 'turnip'
  gem 'rails-footnotes', github: 'josevalim/rails-footnotes'
end

gem 'quiet_assets'
gem 'less-rails'
gem 'execjs'
gem 'sass-rails', '~> 4.0.2'
gem 'bootstrap-sass'

gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'rails-assets'
gem 'rails-assets-jquery-form'
gem 'kaminari'

gem 'therubyracer', platforms: :ruby
gem 'jquery-rails'
gem 'turbolinks'
gem 'jquery-turbolinks'

gem 'html5_validators'

gem 'jbuilder', '~> 1.2'

gem 'settingslogic'

gem 'rails-flog', :require => 'flog'

gem 'dotenv'

gem 'omniauth-github'
gem 'omniauth-facebook'
gem 'omniauth-twitter'
gem 'omniauth-google-oauth2'
gem "i18n-js"
gem 'active_decorator'

gem 'exception_notification', "~> 4.0.1"
gem 'airbrake'
gem 'le'
gem 'newrelic_rpm'
gem "rack-contrib", require: "rack/contrib"
gem 'bcrypt', '~> 3.1.7'

########################################
# Bundle install
########################################
run_inner "bundle config build.nokogiri --use-system-libraries"
run_inner "bundle install"
run_inner "bundle update"
run_inner "bundle install"

########################################
# Guard
########################################
run_inner "bundle exec guard init rspec"

########################################
# Generators
########################################
run_inner 'bundle exec rails g rspec:install'
run_inner "bundle exec rails g rails_footnotes:install"

########################################
# initializer
########################################
@exception_mail = ask("which mail adress does it receive")
initializer 'exception_notification.rb', <<-CODE
unless Rails.env.development?
    PanoAuthor::Application.config.middleware.use ExceptionNotification::Rack,
      email: {
          email_prefix:         "[\#{Rails.env}][#{@app_name}] ",
          sender_address:       ENV['SMTP_USER'],
          exception_recipients: ["#{@exception_mail}"]
      }
end
CODE

########################################
# ENV
########################################
create_file '.env' do
    body = "
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=#{@exception_mail}
SMTP_PASSWD=
"
end

########################################
# Spring
########################################
# run 'bundle exec spring binstub rspec'
run_inner "bundle exec guard init spring"

########################################
# Rspec
########################################
remove_file '.rspec'
create_file '.rspec' do
  body = "-r turnip/rspec --color --format d"
end

########################################
# Files and Directories
########################################
remove_dir 'test'
remove_file 'README.rdoc'
remove_file "public/index.html"

application <<-APPEND_APPLICATION
config.time_zone = 'Tokyo'
config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
config.i18n.default_locale = :ja
config.i18n.locale = :ja
config.assets.precompile += %w(*.png *.jpg *.jpeg *.gif *.woff *.eot *.svg *.ttf admin/*)
config.generators do |g|
g.test_framework = :rspec
g.integration_tool = :rspec
g.fixture_replacement :factory_girl
g.stylesheets = false
g.javascripts = false
g.request_specs false
g.helper        false
g.helper_specs  false
end
APPEND_APPLICATION

environment <<-ADD
  config.action_controller.perform_caching = true
  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
  end
ADD
, env: 'development'


remove_file '.gitignore'
create_file '.gitignore' do
  body = <<EOS
/.bundle
/db/*.sqlite3
/log/*.log
/tmp
.DS_Store
/public/assets*
newrelic.yml
.foreman
.env
doc/
*.swp
*~
.project
.idea
.secret
/*.iml
EOS
end

guard = File.open("#{dir}/Guardfile").read
remove_file 'Guardfile'
create_file 'Guardfile' do
  body = "require 'active_support/inflector'

#{guard}"
end

########################################
# application.yml
########################################
create_file "config/application.yml" do
    body = "defaults: &defaults

development:
  <<: *defaults

test:
  <<: *defaults

staging:
  <<: *defaults

production:
  <<: *defaults
"
end

########################################
# tmuxinator
########################################
create_file "script/#{@app_name}.yml" do 
    body = "
# ~/.tmuxinator/chrhsmt.com.yml

name: \"#{@app_name}\"
root: #{dir}

# Optional tmux socket
# socket_name: foo

# Runs before everything. Use it to start daemons etc.
# pre: sudo /etc/rc.d/mysqld start

# Runs in each window and pane before window/pane specific commands. Useful for setting up interpreter versions.
# pre_window: rbenv shell 2.0.0-p247
pre_window: rvm use #{@ruby_version}@#{@app_name}

# Pass command line options to tmux. Useful for specifying a different tmux.conf.
# tmux_options: -f ~/.tmux.mac.conf

windows:
  - editor:
      layout: main-vertical
      panes:
        - git status
        - sleep 10; bundle exec rails c
        - bundle exec guard
        - bundle exec rails s puma
"
end

########################################
# Git
########################################
git :init
git :add => '.'
git :commit => '-am "Initial commit"'

if yes?('Exist remote repository? [yes/no]')
  @remote_repo = ask("remote repository url is")
  git :remote => "add origin #@remote_repo"
  git :push => '-u origin master'
end

########################################
# Heroku
########################################
if yes?('Deploy to heroku? [yes/no]')
  @heroku_name = ask("heroku app name is")
  run 'heroku create'
  run "heroku rename #@heroku_name"
  git push: 'heroku master'
end

########################################
# tmuxinator
########################################
run "rm -rf ~/.tmuxinator/#{@app_name}.yml"
run "ln -s #{dir}/script/#{app_name}.yml ~/.tmuxinator/#{@app_name}.yml"
run "mux #{@app_name}"

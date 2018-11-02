source 'https://rubygems.org'

gem 'rails', '4.2.1'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

gem 'loofah',  '~> 2.2.3'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'turbolinks' #, git: 'https://github.com/rails/turbolinks'  # because of turbolinks 3.0
gem 'jquery-turbolinks'
gem 'jquery-tablesorter'
gem 'jbuilder', '~> 2.0'
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem 'foundation-rails'
gem 'foundation-icons-sass-rails'
gem 'spinjs-rails'
gem 'coffee_routes'

#gem 'zeroclipboard-rails'

group :development do
  # bundle exec erd --exclude DuplicateDb,CheckProcessScheduler,TestTask --inheritance --polymorphism --notation=uml
  gem "rails-erd"
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'rspec-core'
  gem 'rspec-rails'
  gem 'rspec-expectations'
  gem 'sqlite3'
  gem 'pry-rails'
  gem 'awesome_print'
  gem 'highline'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
  gem 'guard'
  gem 'guard-rspec'
  gem 'spork'
  gem 'growl'

  # gem 'factory_girl_rails'
end

group :production do
  gem 'puma'
  gem 'pg'
end

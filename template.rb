def say_custom(tag, text); say "\033[1m\033[36m" + tag.to_s.rjust(10) + "\033[0m" + "  #{text}" end

def ask_custom(question)
  ask "\033[1m\033[30m\033[46m" + "prompt".rjust(10) + "\033[0m\033[36m" + "  #{question}\033[0m"
end

def prompt_yes?(question)
  answer = ask_custom(question + " \033[33m(y/n)\033[0m")
  case answer.downcase
    when "yes", "y"
      true
    when "no", "n"
      false
    else
      yes_wizard?(question)
  end
end

@after_blocks = []
def 
  after_bundler(&block); @after_blocks << [@current_recipe, block]; 
end

# gems always used

gem 'foreman'
gem 'thin'
gem 'pony', :git => 'git://github.com/benprew/pony.git'

if prompt_yes? "use haml?"
    gem 'haml', '>= 3.1.2'
    gem 'haml-rails', '>=0.3.4', :group => :development
    using_haml = true
end

if prompt_yes? "use compass?"
    gem "compass", :git => 'git://github.com/chriseppstein/compass.git', :branch => 'rails31'
end

if prompt_yes? "use devise?"
    gem 'devise', '>= 1.4.2'
    after_bundler do
        generate :'devise:install'
        generate 'devise user'
    end
end

if prompt_yes? "use jquery ui?"
    inside "app/assets/javascripts" do
        get "https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.15/jquery-ui.min.js", "jqueryui.js"
    end
end

if prompt_yes? "use mongodb and postgresql together?"
    say_custom "todo", "sorry, i haven't implemented that yet. you'll have to figure that one out manually."
elsif prompt_yes? "use mongodb?"
    gem 'bson_ext', '>= 1.3.1'
    gem 'mongoid', '>= 2.1.5'
    after_bundler do
        generate 'mongoid:config'
        say_custom "NOTE!!!", "last i checked, this will put some bad values for production if using heroku. change config/mongoid.yml under production to: uri: <%= ENV['MONGOHQ_URL'] %>"
        remove_file 'config/database.yml'
    end
elsif prompt_yes? "use postgresql?"
    gem 'pg'
end 

initializer "debugger.rb", <<-CONFIG
if defined? Debugger
    Debugger.settings[:autoeval] = true
end
CONFIG

# add some files

get "https://raw.github.com/kylerobson/rails-application-templates/master/files/Procfile"
generate(:controller, "home index")

if using_haml
    get "https://raw.github.com/kylerobson/rails-application-templates/master/files/app/views/layouts/application.html.haml", "app/views/layouts/application.html.haml"
end

# setup mail

get "https://raw.github.com/kylerobson/rails-application-templates/master/files/config/setup_mail.rb", "config/setup_mail.rb"

# todo: add in a css reset

# create staging environment

inside('config/environments') do
    run 'cp production.rb staging.rb'
end

# clean up garbage
run "rm app/assets/images/rails.png"
run "rm public/index.html"
run "rm app/views/layouts/application.html.erb"
run "rm .gitignore"

# finish up

run 'bundle install' # --without production'
say_custom "note", "Running 'after bundler' callbacks."
require 'bundler/setup'
@after_blocks.each{|b| 
    b[1].call
} 

# wrap it up by committing to git

get "https://raw.github.com/kylerobson/rails-application-templates/master/files/gitignore.txt", ".gitignore"
git :init
git add: "."
git commit: "-a -m 'Initial commit'"

namespace :refinery do
  namespace :testing do
    desc "Generates a dummy app for testing"
    task :dummy_app => [:setup_dummy_app, :migrate_dummy_app]

    task :setup_dummy_app do
      require 'refinerycms'

      params = %w(--quiet)
      params << "--database=#{ENV['DB']}" if ENV['DB']

      Refinery::DummyGenerator.start params

      # Load generated dummy app after generation - some of the follow
      # generators depend on Rails.root being available
      # load File.join(ENGINE_PATH, 'spec/dummy/config/environment.rb')

      Refinery::CmsGenerator.start ['--quiet']
      Refinery::CoreGenerator.start ['--quiet']
      Refinery::ResourcesGenerator.start ['--quiet']
      Refinery::PagesGenerator.start ['--quiet']
      Refinery::ImagesGenerator.start ['--quiet']
    end

    task :migrate_dummy_app do
      engines = %w(
        refinery
        refinery_settings
        refinery_authentication
        seo_meta_engine
        refinery_pages
        refinery_images
        refinery_resources
      )

      task_params = [%Q{ bundle exec rake -f #{Refinery::Testing::Railtie.target_engine_path.join('Rakefile')} }]
      task_params << %Q{ app:railties:install:migrations FROM="#{engines.join(', ')}" }
      task_params << %Q{ app:db:drop app:db:create app:db:migrate }
      task_params << %Q{ RAILS_ENV=development --quiet }

      system task_params.join(' ')

      task_params2 = [%Q{ bundle exec rake -f #{Refinery::Testing::Railtie.target_engine_path.join('Rakefile')} }]
      task_params2 << %Q{ app:db:seed app:db:test:prepare }
      task_params2 << %Q{ RAILS_ENV=development --quiet }

      system task_params2.join(' ')
    end

    desc "Remove the dummy app used for testing"
    task :clean_dummy_app do
      path = Refinery::Testing::Railtie.target_engine_path.join('spec', 'dummy')

      path.rmtree if path.exist?
    end

    namespace :engine do
      desc "Initialize the testing environment"
      task :setup => [:init_test_database]

      task :init_test_database => [
        'app:db:migrate',
        'app:db:test:prepare'
      ]
    end
  end
end

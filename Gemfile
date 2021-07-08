source 'https://rubygems.org'

gem 'rake', '~> 10.0'
gem 'redis', '~> 3.0'
gem 'minitest', '~> 4.0'
gem 'cube-ruby', require: "cube"
gem 'ffi', '< 1.9.25'

# Development
gem 'pry', group: :development

# Test
group :test do
  gem 'test-unit-minitest'
end

# NCBO gems (can be from a local dev path or from rubygems/git)
gem 'goo', github: 'ncbo/goo', branch: 'master'
gem 'sparql-client', github: 'ncbo/sparql-client', branch: 'master'
gem 'ontologies_linked_data', github: 'ncbo/ontologies_linked_data', branch: 'master'
gem 'ncbo_resource_index', github: 'ncbo/resource_index'
gem 'ncbo_annotator', github: 'ncbo/ncbo_annotator', branch: 'master'

if ENV['COVERAGE'] == 'true' || ENV['CI'] == 'true'
  require 'simplecov'
  require 'simplecov-cobertura'
  # https://github.com/codecov/ruby-standard-2
  # Generate HTML and Cobertura reports which can be consumed by codecov uploader
  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter
  ])
  SimpleCov.start do
    add_filter '/test/'
    add_filter 'app.rb'
    add_filter 'init.rb'
    add_filter '/config/'
  end
end

require 'ontologies_linked_data'
require 'ncbo_annotator'
require_relative '../lib/ncbo_ontology_recommender'
require_relative '../config/config.test'

# Check to make sure you want to run if not pointed at localhost
safe_host = Regexp.new(/localhost|-ut/)
unless LinkedData.settings.goo_host.match(safe_host) &&
       LinkedData.settings.search_server_url.match(safe_host) &&
       Annotator.settings.annotator_redis_host.match(safe_host)
  print '\n\n================================== WARNING ==================================\n'
  print '** TESTS CAN BE DESTRUCTIVE -- YOU ARE POINTING TO A POTENTIAL PRODUCTION/STAGE SERVER **\n'
  print 'Servers:\n'
  print "triplestore -- #{LinkedData.settings.goo_host}\n"
  print "search -- #{LinkedData.settings.search_server_url}\n"
  print "redis annotator -- #{Annotator.settings.annotator_redis_host}:#{Annotator.settings.annotator_redis_port}\n"
  print "Type 'y' to continue: "
  $stdout.flush
  confirm = $stdin.gets
  abort('Canceling tests...\n\n') unless confirm.strip == 'y'
  print 'Running tests...'
  $stdout.flush
end

require 'minitest/autorun'

class RecommenderUnit
  ANALYTICS_DATA = {
    'BROTEST-0' => {
      2013 => {
        1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 0, 11 => 0, 12 => 0
      },
      2014 => {
        1 => 20, 2 => 30, 3 => 20, 4 => 10, 5 => 20, 6 => 15, 7 => 25, 8 => 20, 9 => 30, 10 => 15, 11 => 20, 12 => 35
      },
      2015 => {
        1 => 10, 2 => 10, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 0, 11 => 0, 12 => 0
      }
    },
    'MCCLTEST-0' => {
      2013 => {
        1 => 2, 2 => 0, 3 => 10, 4 => 2, 5 => 2, 6 => 0, 7 => 6, 8 => 8, 9 => 0, 10 => 0, 11 => 1, 12 => 2
      },
      2014 => {
        1 => 2, 2 => 0, 3 => 0, 4 => 2, 5 => 2, 6 => 0, 7 => 6, 8 => 8, 9 => 0, 10 => 0, 11 => 1, 12 => 2
      },
      2015 => {
        1 => 5, 2 => 6, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 0, 11 => 0, 12 => 0
      }
    },
    'ONTOMATEST-0' => {
      2013 => {
        1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 0, 11 => 0, 12 => 0
      },
      2014 => {
        1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 0, 11 => 0, 12 => 0
      },
      2015 => {
        1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 0, 11 => 0, 12 => 0
      }
    }
  }.freeze

  ONTOLOGY_RANK_DATA = {
    'BROTEST-0' => { bioportalScore: 0.96, umlsScore: 1.0 },
    'MCCLTEST-0' => { bioportalScore: 0.648, umlsScore: 0.0 },
    'ONTOMATEST-0' => { bioportalScore: 0.443, umlsScore: 1.0 }
  }.freeze

  class << self
    attr_accessor :ontologies
  end

  def self.setup_once
    return if @setup_done

    @setup_done = true
    # code to run before the very first test
    LinkedData::SampleData::Ontology.delete_ontologies_and_submissions
    @@ontologies = LinkedData::SampleData::Ontology.sample_owl_ontologies(process_submission: true)
    @@sty = LinkedData::SampleData::Ontology.load_semantic_types_ontology
    annotator = Annotator::Models::NcboAnnotator.new
    annotator.init_redis_for_tests
    annotator.create_term_cache_from_ontologies(@@ontologies, true)
    annotator.redis_switch_instance
    # Ontology analytics data
    annotator.redis.set('ontology_analytics', Marshal.dump(ANALYTICS_DATA))
    annotator.redis.set('ontology_rank', Marshal.dump(ONTOLOGY_RANK_DATA))

    Minitest::Runnable.runnables.each do |suite|
      suite.before_suite if suite.respond_to?(:before_suite)
    end
  end
end

module RecommenderTestSetup
  def before_setup
    RecommenderUnit.setup_once
    super
  end
end

Minitest::Test.prepend(RecommenderTestSetup)

Minitest.after_run do
  Minitest::Runnable.runnables.each do |suite|
    suite.after_suite if suite.respond_to?(:after_suite)
  end

  # code to run after the very last test
  LinkedData::SampleData::Ontology.delete_ontologies_and_submissions
end

# Base test class. Put shared test methods or setup here.
class TestCase < Minitest::Test
end

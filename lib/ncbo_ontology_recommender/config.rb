require 'goo'
require 'ostruct'
require 'set'

module OntologyRecommender
  extend self
  attr_reader :settings

  @settings = OpenStruct.new
  @settings_run = false

  def config(&block)
    return if @settings_run

    # Set defaults
    @settings.input_type ||= 1
    @settings.output_type ||= 1
    @settings.delimiter ||= ','
    # Coverage evaluation
    @settings.wc ||= 0.55
    @settings.pref_score ||= 10
    @settings.syn_score ||= 5
    # According to the annotation score formula, this value ensures that an annotation 'a1' that covers two terms gets
    # a better score than two independent annotations 'a2' and 'a3', even if a1 is SYN and a2 and a3 are PREF
    @settings.multiterm_score ||= 6
    # Specialization evaluation
    @settings.ws ||= 0.15
    # Acceptance evaluation
    @settings.wa ||= 0.15
    @settings.w_bp ||= 0.50
    @settings.w_umls ||= 0.50
    # Detail evaluation
    @settings.wd ||= 0.15
    @settings.top_defs ||= 1
    @settings.top_syns ||= 3
    @settings.top_props ||= 17
    # Other parameters
    @settings.max_elements_set ||= 3
    @settings.max_results_single ||= 25
    @settings.max_results_sets ||= 25

    yield @settings if block_given?
    @settings_run = true
  end

end

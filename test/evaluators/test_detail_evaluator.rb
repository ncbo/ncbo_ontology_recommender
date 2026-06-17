require_relative '../test_case'
require_relative '../../lib/ncbo_ontology_recommender/evaluators/detail_evaluator'
require_relative '../../lib/ncbo_ontology_recommender/helpers/general_helper'

class TestSpecializationEvaluator < TestCase

  def self.before_suite
    top_defs = OntologyRecommender.settings.top_defs
    top_syns = OntologyRecommender.settings.top_syns
    top_props = OntologyRecommender.settings.top_props
    @@detail_evaluator = OntologyRecommender::Evaluators::DetailEvaluator.new(top_defs, top_syns, top_props)
  end

  def self.after_suite
  end

  def test_evaluate
    input = 'article, hormone antagonists, software, activity'
    input_type = 2
    ontologies = []
    annotations_all = OntologyRecommender::Helpers::AnnotatorHelper.get_annotations(input, input_type, ',', ontologies)
    annotations_all_hash = annotations_all.group_by{|ann| ann.annotatedClass.submission.ontology.acronym}
    # Annotations:
    # - MCCLTEST-0 -> hormone antagonists (several props)
    # - ONTOMATEST-0 -> article (several props)
    # - BROTEST-0 -> software (1 def, several props), activity (1 def, 1 syn, several props)
    result1 = @@detail_evaluator.evaluate(annotations_all_hash, annotations_all_hash['MCCLTEST-0'])
    result2 = @@detail_evaluator.evaluate(annotations_all_hash, annotations_all_hash['ONTOMATEST-0'])
    result3 = @@detail_evaluator.evaluate(annotations_all_hash, annotations_all_hash['BROTEST-0'])
    assert(result1.propertiesScore > 0 && result2.propertiesScore > 0 && result3.propertiesScore > 0)
    assert_equal(0, result1.definitionsScore)
    assert_equal(0, result2.definitionsScore)
    assert_equal(1, result3.definitionsScore)
    assert_equal(0, result1.synonymsScore)
    assert_equal(0, result2.synonymsScore)
    assert(result3.synonymsScore > 0)
    assert(result1.normalizedScore > 0 && result2.normalizedScore > 0 && result3.normalizedScore > 0)
    assert(result3.normalizedScore > result1.normalizedScore)
    assert(result3.normalizedScore > result2.normalizedScore)
  end
end
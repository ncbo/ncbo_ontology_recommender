require_relative '../../../lib/ncbo_ontology_recommender/config'
require_relative 'detail_result'

module OntologyRecommender

  module Evaluators
    ##
    # Detail of knowledge evaluator
    class DetailEvaluator
      # - top_defs: minimum number of definitions that a class must have to obtain the max detail score for definitions
      # - top_syns: minimum number of synonyms that a class must have to obtain the max detail score for synonyms
      # - top_props: minimum number of properties that a class must have to obtain the max detail score for properties
      def initialize(top_defs, top_syns, top_props)
        @top_defs = top_defs
        @top_syns = top_syns
        @top_props = top_props
        @features_count_hash = nil
      end

      def evaluate(annotations_all_hash, best_annotations_ont)
        if @features_count_hash.nil?
          @features_count_hash = get_features_count_hash(annotations_all_hash.values.flatten)
        end
        sum_defs = 0
        sum_syns = 0
        sum_props = 0
        best_annotations_ont.each do |ann|
          defs_score_class = get_score(get_number_of_definitions(ann.annotatedClass.id.to_s), @top_defs)
          syns_score_class = get_score(get_number_of_synonyms(ann.annotatedClass.id.to_s), @top_syns)
          props_score_class = get_score(get_number_of_properties(ann.annotatedClass.id.to_s), @top_props)
          sum_defs += defs_score_class
          sum_syns += syns_score_class
          sum_props += props_score_class
        end
        detail_score_defs = sum_defs.to_f / best_annotations_ont.size.to_f
        detail_score_syns = sum_syns.to_f / best_annotations_ont.size.to_f
        detail_score_props = sum_props.to_f / best_annotations_ont.size.to_f
        detail_score = (detail_score_defs + detail_score_syns + detail_score_props).to_f / 3.to_f
        OntologyRecommender::Evaluators::DetailResult.new(detail_score.round(3), detail_score_defs.round(3),
                                                                 detail_score_syns.round(3), detail_score_props.round(3))
      end

      private
      def get_number_of_definitions(class_id)
        !@features_count_hash[class_id].nil? ? (return @features_count_hash[class_id][0]) : (return 0)
      end

      private
      def get_number_of_synonyms(class_id)
        !@features_count_hash[class_id].nil? ? (return @features_count_hash[class_id][1]) : (return 0)
      end

      private
      def get_number_of_properties(class_id)
        !@features_count_hash[class_id].nil? ? (return @features_count_hash[class_id][2]) : (return 0)
      end

      # Returns a Hash |class_id], [x, y, z]|, with x = no. definitions, y = no. synonyms, z = no. properties of the class
      private
      def get_features_count_hash(annotations)
        hash = {}
        classes = annotations.map { |ann| ann.annotatedClass }
        populated_classes = populate_classes(classes, nil)
        populated_classes.each { |cls| hash[cls.id] =
            [(defined? cls.definition) != nil ? cls.definition.size : 0,
             (defined? cls.synonym) != nil ? cls.synonym.size : 0,
             (defined? cls.property) != nil ? cls.property.size : 0] }
        hash
      end

      # Computes the detail score for a specific feature (e.f. definitions, synonyms, properties) (range [0,1])
      private
      def get_score(count, count_for_top_score)
        count >= count_for_top_score ? (return 1) : (return count.to_f / count_for_top_score.to_f)
      end

      ##
      # Populates an array of classes with the information required by the detail evaluator
      private
      def populate_classes(classes, ontology_acronyms=nil)
        class_ids = []
        acronyms = (ontology_acronyms.nil?) ? [] : ontology_acronyms
        classes.each {|c| class_ids << c.id.to_s; acronyms << c.submission.ontology.acronym.to_s unless ontology_acronyms}
        acronyms.uniq!
        old_classes_hash = Hash[classes.map {|cls| [cls.submission.ontology.id.to_s + cls.id.to_s, cls]}]
        params = {"ontology_acronyms" => acronyms}
        # Use a fake phrase because we want a normal wildcard query, not the suggest.
        # Replace this with a wildcard below.
        get_edismax_query("avoid_search_mangling", params)
        params.delete("ontology_acronyms")
        params["qf"] = "resource_id"
        params["fq"] << " AND #{get_terms_field_query_param(class_ids, "resource_id")}"
        params["rows"] = 99999
        # Replace fake query with wildcard
        resp = LinkedData::Models::Class.search("*:*", params)
        populated_classes = []
        resp["response"]["docs"].each do |doc|
          doc = doc.symbolize_keys
          resource_id = doc[:resource_id]
          doc.delete :resource_id
          doc[:id] = resource_id
          ontology_uri = doc[:ontologyId].sub(/\/submissions\/.*/, "")
          ont_uri_class_uri = ontology_uri + resource_id
          old_class = old_classes_hash[ont_uri_class_uri]
          next unless old_class
          doc[:submission] = old_class.submission
          doc[:properties] = MultiJson.load(doc.delete(:propertyRaw))
          populated_classes << LinkedData::Models::Class.read_only(doc)
        end
        populated_classes
      end

      private

      def get_terms_field_query_param(values, field_name)
        return "" if values.nil? || values.empty?

        escaped_values = values.map do |value|
          value.to_s.gsub('\\', '\\\\\\').gsub(',', '\\,').gsub('"', '\\"')
        end

        "_query_:\"{!terms f=#{field_name}}#{escaped_values.join(',')}\""
      end

      def get_edismax_query(text, params={})
        params["defType"] = "edismax"
        params["stopwords"] = "true"
        params["lowercaseOperators"] = "true"
        params["fl"] = "*,score"
        if (text.strip.empty?)
          query = '*'
        else
          query = solr_escape(text)
        end
        params["qf"] = "resource_id^100"
        acronyms = params["ontology_acronyms"] || restricted_ontologies_to_acronyms(params)
        filter_query = get_terms_field_query_param(acronyms, "submissionAcronym")
        params["fq"] = filter_query
        params["q"] = query
        query
      end

      # see https://github.com/rsolr/rsolr/issues/101
      # and https://github.com/projecthydra/active_fedora/commit/75b4afb248ee61d9edb56911b2ef51f30f1ce17f
      #
      def solr_escape(text)
        RSolr.solr_escape(text).gsub(/\s+/,"\\ ")
      end
    end

  end

end
# frozen_string_literal: true
module DiscourseDictionary
  class OxfordApiClient < ::DiscourseDictionary::DictionaryApiClient
    BASE_URL = "https://od-api-sandbox.oxforddictionaries.com/api/v2"

    def self.client
      @@instance ||= create_client
    end

    def self.create_client
      client = OxfordDictionary.new(
        app_id: SiteSetting.discourse_dictionary_oxford_app_id,
        app_key: SiteSetting.discourse_dictionary_oxford_api_key
      )
      
      # Override the internal HTTP client to use sandbox URL
      client.instance_variable_set(:@base_url, BASE_URL)
      client
    end

    def self.reset!
      @@instance = nil
      client
    end

    def self.fetch_from_api(word)
      begin
        response = client().entry(
          word: word,
          dataset: 'en-us',
          params: { fields: 'definitions' }
        )

        results = response.results || []
        definition_collection = []
        results.each do |result|
          result.lexicalEntries.each do |lexicalEntry|
            lexicalCategory = lexicalEntry.lexicalCategory.text
            lexicalEntry.entries.each do |entry|
              entry.senses.each do |sense|
                sense.definitions.each do |definition|
                  definition_collection << {
                    lexical_category: lexicalCategory,
                    definition: definition
                  }.with_indifferent_access
                end
              end
            end
          end
        end

        definition_collection
      rescue => e
        Rails.logger.error("Oxford API Error: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        []
      end
    end
  end
end

# frozen_string_literal: true
module DiscourseDictionary
  class OxfordApiClient < ::DiscourseDictionary::DictionaryApiClient
    def self.client
      @@instance ||= create_client
    end

    def self.create_client
      # Create client with sandbox credentials
      OxfordDictionary.new(
        app_id: SiteSetting.discourse_dictionary_oxford_app_id,
        app_key: SiteSetting.discourse_dictionary_oxford_api_key,
        host: "od-api-sandbox.oxforddictionaries.com"
      )
    end

    def self.reset!
      @@instance = nil
      client
    end

    def self.fetch_from_api(word)
      begin
        Rails.logger.info("=== Oxford API Call Starting ===")
        Rails.logger.info("Word: #{word}")
        
        response = client().entry(
          word: word,
          dataset: 'en-us',
          params: { fields: 'definitions' }
        )

        Rails.logger.info("Response: #{response.inspect}")

        results = response.results || []
        Rails.logger.info("Results count: #{results.count}")
        
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

        Rails.logger.info("Definitions found: #{definition_collection.count}")
        definition_collection
      rescue => e
        Rails.logger.error("Oxford API Error: #{e.class} - #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        []
      end
    end
  end
end

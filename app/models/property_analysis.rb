class PropertyAnalysis < ApplicationRecord
     validates :address, length: { minimum: 5 }

     enum :state, {
        pending: "pending",
        processing: "processing",
        completed: "completed",
        error: "error"
      }

     has_one :result, class_name: "PropertyAnalysisResult", dependent: :destroy

     # Helper method to create a blank result if none exists
     def ensure_result
       build_result if result.nil?
       result
     end

     # Create or update result from analysis content
     def create_or_update_result_from_content(content, model_used = nil)
       # Extract structured data from content
       result_data = PropertyAnalysisResult.extract_from_content(content)

       # Add model information if provided
       result_data[:model_used] = model_used if model_used.present?

       # Print debugging info in tests

       # Create or update result
       if result.present?
         result.update(result_data)
         result
       else
         # Create a new result record
         self.result = PropertyAnalysisResult.new(result_data.merge(property_analysis: self))

         if result.valid?
           save_success = result.save
         else
           Rails.logger.error("Result is invalid: #{result.errors.full_messages.inspect}")
         end

         reload
         result
       end
     end
end

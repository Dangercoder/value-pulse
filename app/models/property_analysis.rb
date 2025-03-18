class PropertyAnalysis < ApplicationRecord
     validates :address, length: { minimum: 5 }

     enum :state, {
        pending: 'pending',
        processing: 'processing',
        completed: 'completed',
        error: 'error'
      }

     has_one :result, class_name: 'PropertyAnalysisResult', dependent: :destroy

     # Helper method to create a blank result if none exists
     def ensure_result
       build_result if result.nil?
       result
     end

     # Create or update result from analysis content
     def create_or_update_result_from_content(content, model_used = nil)
       # Return nil if no content provided
       return nil if content.blank?
       
       # Extract structured data from content
       result_data = PropertyAnalysisResult.extract_from_content(content)
       
       # Add model information if provided
       result_data[:model_used] = model_used if model_used.present?
       
       # Create or update result
       if result.present?
         result.update(result_data)
         result
       else
         create_result(result_data)
       end
     rescue => e
       Rails.logger.error("Error creating/updating result: #{e.message}")
       Rails.logger.error(e.backtrace.join("\n"))
       nil
     end
end

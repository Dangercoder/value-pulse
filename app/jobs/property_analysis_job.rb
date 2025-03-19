class PropertyAnalysisJob < ApplicationJob
  queue_as :default

  def perform(property_analysis_id, session_id)
    # Log the start of analysis
    Rails.logger.info("Starting property analysis job for: #{property_analysis_id}")

    begin
      # Find the property analysis record
      property_analysis = PropertyAnalysis.find(property_analysis_id)

      # Use the PropertyAnalysisService to perform the analysis
      service = PropertyAnalysisService.new(property_analysis)
      analysis_result = service.perform_analysis(session_id)
      
      # Reload to get the latest data with the result
      property_analysis.reload
      property_result = property_analysis.result

      # Broadcast the result back to the client
      Turbo::StreamsChannel.broadcast_update_to(
        "property_analysis_#{session_id}",
        target: "analysis_result",
        partial: "property_analysis/result",
        locals: { 
          analysis: analysis_result,
          property_analysis: property_analysis,
          property_result: property_result
        }
      )

    rescue => e
      Rails.logger.error("Error in property analysis job: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      # Broadcast error message using the error partial
      Turbo::StreamsChannel.broadcast_update_to(
        "property_analysis_#{session_id}",
        target: "analysis_result",
        partial: "property_analysis/error",
        locals: { message: "An error occurred during property analysis: #{e.message}" }
      )
    end
  end
end

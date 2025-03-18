class PropertyAnalysisJob < ApplicationJob
  queue_as :default

  def perform(address, additional_info, session_id)
    # Log the start of analysis
    Rails.logger.info("Starting property analysis for: #{address}")

    begin
      # Perform property analysis using RubyLLM
      analysis_result = analyze_property(address, additional_info)

      # Broadcast the result back to the client
      Turbo::StreamsChannel.broadcast_update_to(
        "property_analysis_#{session_id}",
        target: "analysis_result",
        partial: "property_analysis/result",
        locals: { analysis: analysis_result }
      )

      # Save the analysis to the database if needed
      # PropertyAnalysis.create!(
      #   address: address,
      #   additional_info: additional_info,
      #   result: analysis_result,
      #   session_id: session_id
      # )

    rescue => e
      Rails.logger.error("Error in property analysis: #{e.message}")

      # Broadcast error message
      Turbo::StreamsChannel.broadcast_update_to(
        "property_analysis_#{session_id}",
        target: "analysis_result",
        partial: "property_analysis/error",
        locals: { message: "An error occurred during property analysis: #{e.message}" }
      )
    end
  end

  private

  def analyze_property(address, additional_info)
    # Create a description of the property
    property_description = generate_property_description(address, additional_info)

    # Create a chat with Anthropic's Claude model
    chat = RubyLLM.chat(model: "claude-3-7-sonnet-20250219")
    model_name = "claude-3-7-sonnet-20250219" # Store the model name directly

    # Ask Claude to analyze and valuate the property
    prompt = <<~PROMPT
      You are an expert real estate appraiser. I need you to estimate the value of a property with the following details:

      #{property_description}

      Please provide a valuation in HTML format with the following sections clearly labeled with their respective headings.
      Each heading must be exactly as shown (including capitalization and colon):

      1. "Property Valuation: [ADDRESS]" - Clearly state the full address here
      2. "Property Type: [TYPE]" - State if it's an apartment, house, villa, condo, etc.
      3. "Estimated Value Range: [MIN] - [MAX]" - Include the currency with the values
      4. "Confidence Level: [LEVEL]" - Must be exactly one of these words: Low, Medium, or High
      5. "Key Factors Affecting Valuation:" - List key factors (location, size, market conditions)
      6. "Recommendations for Increasing Property Value:" - List 2-4 specific recommendations

      Important format requirements:
      - For "Confidence Level:", use ONLY one of these exact words: "Low", "Medium", or "High" (correct capitalization)
      - Present the estimated value range in the appropriate currency for the property's location
      - Use h3 tags for section headings
      - Use ul/li tags for lists of factors and recommendations
      - Keep explanations concise and factual
      - If information is missing, acknowledge this in the relevant sections

      The output will be displayed directly to users in a web application.
    PROMPT

    # Get the AI response
    response = chat.ask(prompt)

    # Return the content from the response
    {
      content: response.content,
      model_used: model_name,
      address: address,
      timestamp: Time.current.to_s
    }
  end

  def generate_property_description(address, additional_info)
    description = []
    description << "Address: #{address}" if address.present?

    # Parse additional info if it's in a structured format
    # This would depend on how your form sends the additional info
    if additional_info.present?
      description << "Additional Information: #{additional_info}"
    end

    description.join("\n")
  end
end

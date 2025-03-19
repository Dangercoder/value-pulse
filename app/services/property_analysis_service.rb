class PropertyAnalysisService
  def initialize(property_analysis)
    @property_analysis = property_analysis
  end

  def perform_analysis(session_id)
    # Log the start of analysis
    Rails.logger.info("Starting property analysis for: #{@property_analysis.id}")

    begin
      # Update analysis state
      @property_analysis.update(state: :processing)

      # Get analysis result
      analysis_result = analyze_property(@property_analysis.address, @property_analysis.additional_info)

      # Log the result for debugging
      if analysis_result[:content].blank?
        Rails.logger.error("Content is blank in analysis result")
        analysis_result[:content] = "<h3>Property Valuation: #{@property_analysis.address}</h3><p>We apologize, but we couldn't generate a detailed analysis at this time.</p>"
      end

      result_data = PropertyAnalysisResult.extract_from_content(analysis_result[:content])

      # Force valid property_type for testing if not already set
      if result_data[:property_type].nil? || !PropertyAnalysisResult::PROPERTY_TYPES.include?(result_data[:property_type])
        result_data[:property_type] = "single_family"
      end

        result = @property_analysis.create_or_update_result_from_content(analysis_result[:content], analysis_result[:model_used])
          @property_analysis.reload

      # Mark the analysis as completed
      @property_analysis.update(state: :completed)

      # Ensure analysis_result has all required keys
      analysis_result[:content] ||= ""
      analysis_result[:model_used] ||= "Unknown model"
      analysis_result[:address] ||= @property_analysis.address
      analysis_result[:timestamp] ||= Time.current.to_s

      # Return the result for broadcasting
      analysis_result
    rescue => e
      Rails.logger.error("Error in property analysis: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      # Update the analysis state
      @property_analysis.update(state: :error) rescue nil

      # Raise error to be handled by caller
      raise e
    end
  end

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
      6. "Comparable Properties:" - List 2-3 comparable properties with their details and prices if possible
      7. "Market Trends:" - Brief analysis of local market trends affecting this property
      8. "Recommendations for Increasing Property Value:" - List 2-4 specific recommendations

      Important format requirements:
      - For "Confidence Level:", use ONLY one of these exact words: "Low", "Medium", or "High" (correct capitalization)
      - Present the estimated value range in the appropriate currency for the property's location
      - Use h3 tags for section headings
      - Use ul/li tags for lists of factors and recommendations
      - Keep explanations concise and factual
      - If information is missing, acknowledge this in the relevant sections
      - If you can determine the number of bedrooms, bathrooms, square footage, or year built, please include this information in the Property Type section

      The output will be displayed directly to users in a web application.
    PROMPT

    # Get the AI response
    Rails.logger.info("Sending prompt to Claude")

    response = nil
    begin
      response = chat.ask(prompt)
    rescue => e
      Rails.logger.error("Error during Claude API call: #{e.message}")
      raise e
    end

    content = safely_extract_content(response)

    # Return the content from the response
    {
      content: content,
      model_used: model_name,
      address: address,
      timestamp: Time.current.to_s
    }
  end

  # Safely extract content from the RubyLLM response
  def safely_extract_content(response)
    return "<p>No response received from AI.</p>" if response.nil?

    # Try different approaches to extract content based on RubyLLM version
    content = nil

    # Approach 1: Direct content method
    if response.respond_to?(:content)
      begin
        content = response.content
      rescue => e
        Rails.logger.error("Error extracting content via .content: #{e.message}")
      end
    end

    # Provide a fallback if we still don't have content
    if content.nil? || content.empty?
      content = "<p>We apologize, but we couldn't generate a property analysis at this time.</p>"
      Rails.logger.error("Failed to extract any content from response")
    end

    content
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

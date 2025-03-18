class Valuation < ApplicationRecord
  belongs_to :property

  validates :ai_response, presence: true
  validates :model_used, presence: true

  def parsed_response
    return {} if ai_response.blank?

    # This is a simple parsing implementation
    # You could implement more sophisticated parsing based on your needs
    {
      estimated_value_range: extract_value_range,
      confidence_level: extract_confidence_level,
      key_factors: extract_key_factors,
      recommendations: extract_recommendations
    }
  end

  private

  def extract_value_range
    # Simple extraction logic - could be improved with regex or NLP
    if ai_response.match(/\$[\d,]+\s*-\s*\$[\d,]+/)
      ai_response.match(/\$[\d,]+\s*-\s*\$[\d,]+/)[0]
    else
      "Not specified"
    end
  end

  def extract_confidence_level
    if ai_response.downcase.include?("confidence")
      if ai_response.downcase.include?("high confidence")
        "High"
      elsif ai_response.downcase.include?("medium confidence")
        "Medium"
      elsif ai_response.downcase.include?("low confidence")
        "Low"
      else
        "Not specified"
      end
    else
      "Not specified"
    end
  end

  def extract_key_factors
    # Trying to extract the key factors section
    # This is a very simple implementation and might need improvement
    if ai_response.match(/key factors[:\n]+(.*?)(?=recommendations|\z)/im)
      ai_response.match(/key factors[:\n]+(.*?)(?=recommendations|\z)/im)[1].strip
    else
      "Not specified"
    end
  end

  def extract_recommendations
    # Trying to extract the recommendations section
    if ai_response.match(/recommendations[:\n]+(.*?)(?=\z)/im)
      ai_response.match(/recommendations[:\n]+(.*?)(?=\z)/im)[1].strip
    else
      "Not specified"
    end
  end
end

class PropertyAnalysisResult < ApplicationRecord
  belongs_to :property_analysis

  validates :property_analysis, presence: true
  validates :estimated_price, numericality: { greater_than: 0 }, allow_nil: true
  validates :min_price, numericality: { greater_than: 0 }, allow_nil: true
  validates :max_price, numericality: { greater_than: 0 }, allow_nil: true
  validates :bedrooms, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :bathrooms, numericality: { greater_than: 0 }, allow_nil: true
  validates :square_footage, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :year_built, numericality: { only_integer: true, greater_than: 1800, less_than_or_equal_to: -> { Date.current.year } }, allow_nil: true
  validates :rental_potential, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  # Define investment rating enum values
  INVESTMENT_RATINGS = %w[poor below_average average above_average excellent].freeze
  validates :investment_rating, inclusion: { in: INVESTMENT_RATINGS }, allow_nil: true

  # Define property types
  PROPERTY_TYPES = %w[single_family multi_family condo townhouse mobile_home land commercial residential].freeze
  validates :property_type, inclusion: { in: PROPERTY_TYPES }, allow_nil: true

  # Define neighborhood quality levels
  NEIGHBORHOOD_QUALITIES = %w[poor below_average average above_average excellent].freeze
  validates :neighborhood_quality, inclusion: { in: NEIGHBORHOOD_QUALITIES }, allow_nil: true

  # Define confidence levels
  CONFIDENCE_LEVELS = %w[low medium high].freeze
  validates :confidence_level, inclusion: { in: CONFIDENCE_LEVELS }, allow_nil: true

  # Helper to check if price is a range
  def price_range?
    min_price.present? && max_price.present?
  end

  # Helper to get price display
  def price_display
    return price_display_text if price_display_text.present?

    if estimated_price.present?
      "$#{estimated_price.to_i}"
    elsif price_range?
      "$#{min_price.to_i} - $#{max_price.to_i}"
    else
      "Price information unavailable"
    end
  end

  # Helper to get confidence level color classes for UI
  def confidence_color_classes
    colors = {
      "low" => "bg-red-100 text-red-800 border-red-300",
      "medium" => "bg-yellow-100 text-yellow-800 border-yellow-300",
      "high" => "bg-green-100 text-green-800 border-green-300"
    }

    colors[confidence_level] || "bg-gray-100 text-gray-800 border-gray-300"
  end

  # Extract structured data from raw analysis content
  def self.extract_from_content(content)
    result = {}

    # Return empty result if content is nil or empty
    return result if content.blank?

    # Extract property type
    if content =~ /<h3>Property Type:\s*([^<\n]+)<\/h3>|Property Type:\s*([^<\n]+)/
      property_type = ($1 || $2).strip.downcase.gsub(/\s+/, "_")

      # Map the extracted property type to one of the allowed PROPERTY_TYPES
      case property_type
      when /single_family_home/
        result[:property_type] = "single_family"
      when /multi_family_home/
        result[:property_type] = "multi_family"
      when /condo(minium)?/
        result[:property_type] = "condo"
      when /town_?house/
        result[:property_type] = "townhouse"
      when /mobile_home/
        result[:property_type] = "mobile_home"
      when /land|lot|vacant/
        result[:property_type] = "land"
      when /commercial/
        result[:property_type] = "commercial"
      when /residential/
        result[:property_type] = "residential"
      else
        # If we can't map it directly, try to find the closest match
        PROPERTY_TYPES.each do |valid_type|
          if property_type.include?(valid_type)
            result[:property_type] = valid_type
            break
          end
        end

        # Default to single_family if no match found
        result[:property_type] ||= "single_family"
      end
    end

    # Extract price range
    if content =~ /<h3>Estimated Value Range:?\s*\$?([\d,]+)\s*-\s*\$?([\d,]+)<\/h3>|Estimated Value Range:?\s*\$?([\d,]+)\s*-\s*\$?([\d,]+)/i
      min_price = $1 || $3
      max_price = $2 || $4
      result[:min_price] = min_price.gsub(",", "").to_i
      result[:max_price] = max_price.gsub(",", "").to_i
      result[:price_display_text] = "$#{min_price} - $#{max_price}"
    elsif content =~ /<h3>Estimated Value:?\s*\$?([\d,]+)<\/h3>|Estimated Value:?\s*\$?([\d,]+)/i
      price = $1 || $2
      result[:estimated_price] = price.gsub(",", "").to_i
      result[:price_display_text] = "$#{price}"
    end

    # Extract confidence level
    if content =~ /<h3>Confidence Level:?\s*(Low|Medium|High)<\/h3>|Confidence Level:?\s*(Low|Medium|High)/i
      confidence = $1 || $2
      result[:confidence_level] = confidence.downcase
    end

    # Extract key factors if present
    if content =~ /<h3>Key Factors Affecting Valuation:<\/h3>\s*(.+?)(?=<h3>|$)/mi
      result[:key_factors] = $1.strip
    end

    # Extract comparable properties if present
    if content =~ /<h3>Comparable Properties:<\/h3>\s*(.+?)(?=<h3>|$)/mi
      result[:comparable_properties] = $1.strip
    end

    # Extract market trends if present
    if content =~ /<h3>Market Trends:<\/h3>\s*(.+?)(?=<h3>|$)/mi
      result[:market_trends] = $1.strip
    end

    # Extract bedrooms and bathrooms if present
    if content =~ /(\d+)\s*bedrooms?/i || content =~ /(\d+)\s*bed/i
      result[:bedrooms] = $1.to_i
    end

    if content =~ /(\d+(?:\.\d+)?)\s*bathrooms?/i || content =~ /(\d+(?:\.\d+)?)\s*bath/i
      result[:bathrooms] = $1.to_f
    end

    # Extract square footage if present
    if content =~ /(\d+(?:,\d+)?)\s*(?:sq\.?\s*ft\.?|square feet|square foot|sq ft)/i
      result[:square_footage] = $1.gsub(",", "").to_i
    end

    # Extract year built if present
    if content =~ /built in (\d{4})/i || content =~ /built:? (\d{4})/i || content =~ /year built:? (\d{4})/i
      result[:year_built] = $1.to_i
    end

    result
  end
end

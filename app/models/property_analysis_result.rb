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
    if content =~ /Property Type:\s*([^<\n]+)/
      result[:property_type] = $1.strip.downcase.gsub(/\s+/, '_')
    end
    
    # Extract price range
    if content =~ /Estimated Value Range:?\s*\$?([\d,]+)\s*-\s*\$?([\d,]+)/i
      result[:min_price] = $1.gsub(',', '').to_i
      result[:max_price] = $2.gsub(',', '').to_i
      result[:price_display_text] = "$#{$1} - $#{$2}"
    elsif content =~ /Estimated Value:?\s*\$?([\d,]+)/i
      result[:estimated_price] = $1.gsub(',', '').to_i
      result[:price_display_text] = "$#{$1}"
    end
    
    # Extract confidence level
    if content =~ /confidence level:?\s*(Low|Medium|High)/i
      result[:confidence_level] = $1.downcase
    end
    
    # Extract key factors if present
    if content =~ /Key Factors:?\s*(.+?)(?=Comparable Properties:|Market Trends:|Confidence Level:|$)/mi
      result[:key_factors] = $1.strip
    end
    
    # Extract comparable properties if present
    if content =~ /Comparable Properties:?\s*(.+?)(?=Market Trends:|Confidence Level:|$)/mi
      result[:comparable_properties] = $1.strip
    end
    
    # Extract market trends if present
    if content =~ /Market Trends:?\s*(.+?)(?=Confidence Level:|$)/mi
      result[:market_trends] = $1.strip
    end
    
    # Extract bedrooms and bathrooms if present
    if content =~ /(\d+)\s*bedroom/i
      result[:bedrooms] = $1.to_i
    end
    
    if content =~ /(\d+(?:\.\d+)?)\s*bathroom/i
      result[:bathrooms] = $1.to_f
    end
    
    # Extract square footage if present
    if content =~ /(\d+(?:,\d+)?)\s*(?:sq\.?\s*ft\.?|square feet)/i
      result[:square_footage] = $1.gsub(',', '').to_i
    end
    
    # Extract year built if present
    if content =~ /built in (\d{4})/i
      result[:year_built] = $1.to_i
    end
    
    result
  end
end 
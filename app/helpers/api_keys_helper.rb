module ApiKeysHelper
  # Returns the Google Maps API key with proper escaping for use in JavaScript
  def google_maps_api_key
    key = ENV["GOOGLE_MAPS_API_KEY"].to_s.strip
    
    if key.blank?
      if Rails.env.development?
        # Try to get from credentials in development
        key = Rails.application.credentials.dig(:google_maps, :api_key).to_s
      end
      
      # Log a warning if still blank
      if key.blank? && (Rails.env.development? || Rails.env.test?)
        Rails.logger.warn "Google Maps API key is not set. Address autocomplete will not work."
      end
    end
    
    # HTML escape the key to prevent XSS
    ERB::Util.html_escape(key)
  end
end 
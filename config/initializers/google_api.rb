# Set Google Maps API key for use in JavaScript
Rails.application.config.after_initialize do
  # Make sure the Google Maps API key is set from environment variables
  if ENV["GOOGLE_MAPS_API_KEY"].blank?
    # For development, try to use credentials if environment variable is not set
    api_key = Rails.application.credentials.dig(:google_maps, :api_key)
    
    if api_key.present?
      ENV["GOOGLE_MAPS_API_KEY"] = api_key
    else
      # Only show this message in development to avoid leaking info in production
      Rails.logger.warn "Google Maps API key not found in environment or credentials" if Rails.env.development?
      ENV["GOOGLE_MAPS_API_KEY"] = ""
    end
  end
end 
class PlacesApiController < ApplicationController
  require 'net/http'
  require 'uri'
  require 'json'

  # Endpoint for address autocomplete suggestions
  def autocomplete
    query = params[:query]
    
    if query.blank? || query.length < 2
      render json: { predictions: [] }
      return
    end
    
    # Call the Places API v1 Text Search endpoint
    uri = URI.parse("https://places.googleapis.com/v1/places:searchText")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["X-Goog-Api-Key"] = ENV["GOOGLE_MAPS_API_KEY"]
    request["X-Goog-FieldMask"] = "places.displayName,places.formattedAddress,places.id,places.location"
    
    # Configure the request with appropriate parameters - using the Text Search format
    request.body = JSON.dump({
      "textQuery" => query
    })
    
    # Send the request
    response = nil
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      response = http.request(request)
    end
    
    # Parse and prepare the response
    if response.code == "200"
      result = JSON.parse(response.body)
      
      predictions = result["places"].map do |place|
        {
          place_id: place["id"],
          description: place["formattedAddress"],
          name: place["displayName"]["text"],
          latitude: place["location"] ? place["location"]["latitude"] : nil,
          longitude: place["location"] ? place["location"]["longitude"] : nil
        }
      end
      
      render json: { predictions: predictions }
    else
      Rails.logger.error("Places API error: #{response.body}")
      render json: { error: "Error fetching suggestions", code: response.code }, status: :service_unavailable
    end
  end
  
  # Endpoint for place details
  def details
    place_id = params[:place_id]
    
    if place_id.blank?
      render json: { error: "Place ID is required" }, status: :bad_request
      return
    end
    
    # Call the Places API v1 details endpoint
    uri = URI.parse("https://places.googleapis.com/v1/places/#{place_id}")
    request = Net::HTTP::Get.new(uri)
    request["X-Goog-Api-Key"] = ENV["GOOGLE_MAPS_API_KEY"]
    request["X-Goog-FieldMask"] = "id,displayName,formattedAddress,location,addressComponents"
    
    # Send the request
    response = nil
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      response = http.request(request)
    end
    
    # Parse and prepare the response
    if response.code == "200"
      render json: JSON.parse(response.body)
    else
      Rails.logger.error("Places API error: #{response.body}")
      render json: { error: "Error fetching place details", code: response.code }, status: :service_unavailable
    end
  end
end 
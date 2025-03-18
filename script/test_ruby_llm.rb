#!/usr/bin/env ruby

# This script tests your RubyLLM configuration with a simple property analysis
# Run it with: bundle exec ruby script/test_ruby_llm.rb

require_relative '../config/environment'
require 'dotenv/load'

puts "=== RubyLLM Configuration Test (Anthropic Claude) ==="
puts

# Display configuration
puts "API Keys configured:"
puts "  OpenAI:     #{RubyLLM.configuration.openai_api_key ? '✓' : '✗'}"
puts "  Anthropic:  #{RubyLLM.configuration.anthropic_api_key ? '✓' : '✗'}"
puts "  Gemini:     #{RubyLLM.configuration.gemini_api_key ? '✓' : '✗'}"
puts "  DeepSeek:   #{RubyLLM.configuration.deepseek_api_key ? '✓' : '✗'}"
puts

# Check if Anthropic API key is configured
unless RubyLLM.configuration.anthropic_api_key
  puts "⚠️  WARNING: Anthropic API key is not configured."
  puts "Please add your ANTHROPIC_API_KEY to the .env file and try again."
  exit 1
end

# Test property address (change to test with different addresses)
test_address = "123 Main Street, San Francisco, CA 94103"
test_info = "3 bedroom, 2 bathroom house built in 1985. Recently renovated kitchen."

puts "Testing property analysis with Claude:"
puts "  Address: #{test_address}"
puts "  Info:    #{test_info}"
puts
puts "Sending request to Anthropic Claude..."

begin
  # Create a new chat with Claude model
  chat = RubyLLM.chat(model: 'claude-3-7-sonnet-20250219')
  
  # Prepare the prompt
  prompt = <<~PROMPT
    You are an expert real estate appraiser. I need you to estimate the value of a property with the following details:
    
    Address: #{test_address}
    Additional Details: #{test_info}
    
    Please provide a valuation with the following structure:
    
    1. Estimated value range (minimum and maximum)
    2. Confidence level (low, medium, high)
    3. Key factors affecting the valuation
    4. Recommendations for potentially increasing the property value
  PROMPT
  
  # Send to Claude
  puts "Using model: #{chat.model}"
  
  # Ask with response streaming
  puts
  puts "=== Claude Response ==="
  puts
  
  response = chat.ask(prompt) do |chunk|
    print chunk.content
  end
  
  puts
  puts
  puts "=== Analysis Complete ==="
  puts "Response generated successfully using #{chat.model}"
  puts "If you see a property valuation above, your Anthropic Claude configuration is working correctly!"
  
rescue => e
  puts
  puts "ERROR: #{e.message}"
  puts
  puts "Troubleshooting tips:"
  puts "1. Check that your ANTHROPIC_API_KEY in .env file is correct"
  puts "2. Make sure the .env file is loaded properly"
  puts "3. Check your internet connection"
  puts "4. Verify API quotas/limits haven't been exceeded"
  puts
  puts e.backtrace.join("\n") if ENV['DEBUG']
end 
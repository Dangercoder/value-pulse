# Configure RubyLLM API keys and default settings
RubyLLM.configure do |config|
  # API keys for different LLM providers
  config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
  config.openai_api_key = ENV['OPENAI_API_KEY']
  config.gemini_api_key = ENV['GEMINI_API_KEY']
  config.deepseek_api_key = ENV['DEEPSEEK_API_KEY'] # Optional
end 
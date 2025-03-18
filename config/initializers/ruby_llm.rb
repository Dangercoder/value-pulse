# Configure RubyLLM API keys and default settings
RubyLLM.configure do |config|
  # API keys for different LLM providers
  config.openai_api_key = ENV['OPENAI_API_KEY']
  config.anthropic_api_key = ENV['ANTHROPIC_API_KEY']
  config.gemini_api_key = ENV['GEMINI_API_KEY']
  config.deepseek_api_key = ENV['DEEPSEEK_API_KEY'] # Optional

  # Default models (optional)
  # config.default_chat_model = 'gpt-4o-mini'
  # config.default_embedding_model = 'text-embedding-3-small'
  
  # Logging (optional)
  # config.logger = Rails.logger
  # config.log_level = :info
end 
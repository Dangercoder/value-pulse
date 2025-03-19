# Value Pulse - AI-Powered Property Valuation

AVM example application that uses AI to analyze and estimate property values.

* Developed with ruby `ruby 3.4.2 (2025-02-15 revision d2930f8e7a) +PRISM [arm64-darwin24]`
* Uses https://github.com/kirillplatonov/hotwire-livereload for hot reload

## AI Property Valuation

This application uses RubyLLM with Anthropic's Claude AI model to provide automated property valuations. When users enter a property address and additional information, the system:

1. Sends the property details to Anthropic's Claude
2. Claude analyzes the property and generates a valuation report
3. The valuation is displayed to the user in real-time using Hotwire Turbo Streams

## Setup

### API Keys

To use this application, you need to set up your Anthropic API key:

1. Create a `.env` file in the root directory (it's already in `.gitignore`)
2. Add your Anthropic API key to the `.env` file:
   ```
   ANTHROPIC_API_KEY=your_anthropic_api_key_here
   ```

### Installing dev dependencies 
Run `sh ./setup.sh`

### Testing the AI Connection

To test if your Anthropic Claude configuration is working:

```bash
# Run the test script
bundle exec ruby script/test_ruby_llm.rb
```

This script will attempt to perform a sample property analysis using Claude and show you the results directly in the terminal.

## Configuration

The RubyLLM configuration is in `config/initializers/ruby_llm.rb`. By default, it's set to use Anthropic's Claude 3.7 Sonnet model. You can modify this file if you want to use a different model or provider.

## Usage

1. Navigate to the home page
2. Enter a property address and any additional information
3. Click "Analyze Property"
4. Wait for Claude to analyze the property (typically 10-15 seconds)
5. View the detailed property valuation

# Check if PostgreSQL 17 is already installed
if brew list postgresql@17 &>/dev/null; then
  echo "PostgreSQL 17 is already installed"
else
  echo "Installing PostgreSQL 17..."
  brew install postgresql@17
fi

# Install libpq (PostgreSQL client library)
if brew list libpq &>/dev/null; then
  echo "libpq is already installed"
else
  echo "Installing libpq..."
  brew install libpq
fi

# Check if PostgreSQL 17 service is already running
if brew services list | grep postgresql@17 | grep started &>/dev/null; then
  echo "PostgreSQL 17 service is already running"
else
  echo "Starting PostgreSQL 17 service..."
  brew services start postgresql@17
fi

# Configure bundler to use libpq properly
echo "Configuring bundler to use libpq..."
bundle config --local build.pg --with-opt-dir=$(brew --prefix libpq)

# Install Ruby gems from Gemfile
echo "Installing gems from Gemfile..."
bundle install

bin/rails db:create

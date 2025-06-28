# Sample Rails Application with Test Sentinel

This is a sample Rails application demonstrating the integration of Test Sentinel, an AI-powered test coverage analysis tool.

## Test Sentinel Integration

Test Sentinel analyzes your codebase to identify methods that most urgently need test coverage based on:

- **Test Coverage**: Methods with low coverage get higher priority
- **Code Complexity**: Complex methods (high cyclomatic complexity) are prioritized  
- **Git Activity**: Frequently changed files get attention
- **Directory Importance**: Models and services are weighted higher than helpers

### Usage

#### Basic Analysis
```bash
# Analyze top 3 methods (default)
bundle exec test-sentinel generate

# Analyze top 10 methods
bundle exec test-sentinel generate --top-n 10

# Use custom config file
bundle exec test-sentinel generate --config custom_sentinel.yml
```

#### Using Rake Tasks
```bash
# Quick analysis (top 5)
bundle exec rake test_sentinel:analyze

# Full analysis (top 10)  
bundle exec rake test_sentinel:full_analysis

# Custom number of methods
bundle exec rake test_sentinel:analyze[7]
```

### Configuration

Test Sentinel can be configured via `sentinel.yml`:

```yaml
score_weights:
  coverage: 1.5      # Weight for coverage factor
  complexity: 1.0    # Weight for complexity factor
  git_history: 0.8   # Weight for git activity
  directory: 1.2     # Weight for directory importance

directory_weights:
  - path: "app/models/"
    weight: 1.5      # Higher priority for models
  - path: "app/services/"  
    weight: 1.5      # Higher priority for services

exclude:
  - "app/helpers/**/*"  # Exclude helpers from analysis
```

### Example Output

```
🔍 Analyzing codebase...

📊 Top 3 methods requiring test coverage:

1. app/models/user.rb:19
   Method: can_access_feature?
   Priority Score: 9.55
   Coverage: 50.0%
   Complexity: 7
   Git Commits: 0

2. app/services/payment_service.rb:6
   Method: calculate_fee
   Priority Score: 7.45
   Coverage: 56.8%
   Complexity: 5
   Git Commits: 0

📄 Detailed analysis saved to test_sentinel_analysis.json
```

### CI/CD Integration

Test Sentinel is integrated into the GitHub Actions workflow to:

1. Run tests and generate coverage data
2. Analyze codebase with Test Sentinel
3. Upload analysis results as artifacts
4. Provide feedback on test coverage gaps

### Getting Started

1. Run the existing tests to generate coverage data:
   ```bash
   bundle exec rspec
   ```

2. Run Test Sentinel analysis:
   ```bash
   bundle exec test-sentinel generate
   ```

3. Review the JSON output for detailed recommendations:
   ```bash
   cat test_sentinel_analysis.json
   ```

## Application Structure

This sample app includes:

- **User model** with complex business logic methods
- **PaymentService** with various payment processing methods  
- **UsersController** with standard CRUD operations
- **RSpec tests** with partial coverage to demonstrate Test Sentinel's capabilities

The application is intentionally designed with some methods having low test coverage to showcase Test Sentinel's analysis capabilities.

## Setup

### Requirements

- Ruby 3.3.1
- Rails 8.0.2
- SQLite3

### Installation

1. Install dependencies:
   ```bash
   bundle install
   ```

2. Set up database:
   ```bash
   bundle exec rails db:create
   bundle exec rails db:migrate
   ```

3. Run tests:
   ```bash
   bundle exec rspec
   ```

4. Analyze with Test Sentinel:
   ```bash
   bundle exec test-sentinel generate
   ```
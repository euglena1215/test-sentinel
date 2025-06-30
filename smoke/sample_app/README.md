# Sample Rails Application with Code Qualia

This is a sample Rails application demonstrating the integration of Code Qualia, an AI-powered test coverage analysis tool.

## Code Qualia Integration

Code Qualia analyzes your codebase to identify methods that most urgently need test coverage based on:

- **Test Coverage**: Methods with low coverage get higher priority
- **Code Complexity**: Complex methods (high cyclomatic complexity) are prioritized  
- **Git Activity**: Frequently changed files get attention
- **Directory Importance**: Models and services are weighted higher than helpers

### Usage

#### Basic Analysis
```bash
# Analyze top 3 methods (default)
bundle exec code-qualia generate

# Analyze top 10 methods
bundle exec code-qualia generate --top-n 10

# Use custom config file
bundle exec code-qualia generate --config custom_qualia.yml
```

#### Using Rake Tasks
```bash
# Quick analysis (top 5)
bundle exec rake code_qualia:analyze

# Full analysis (top 10)  
bundle exec rake code_qualia:full_analysis

# Custom number of methods
bundle exec rake code_qualia:analyze[7]
```

### Configuration

Code Qualia can be configured via `qualia.yml`:

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

📄 Detailed analysis saved to code_qualia_analysis.json
```

### CI/CD Integration

Code Qualia is integrated into the GitHub Actions workflow to:

1. Run tests and generate coverage data
2. Analyze codebase with Code Qualia
3. Upload analysis results as artifacts
4. Provide feedback on test coverage gaps

### Getting Started

1. Run the existing tests to generate coverage data:
   ```bash
   bundle exec rspec
   ```

2. Run Code Qualia analysis:
   ```bash
   bundle exec code-qualia generate
   ```

3. Review the JSON output for detailed recommendations:
   ```bash
   cat code_qualia_analysis.json
   ```

## Application Structure

This sample app includes:

- **User model** with complex business logic methods
- **PaymentService** with various payment processing methods  
- **UsersController** with standard CRUD operations
- **RSpec tests** with partial coverage to demonstrate Code Qualia's capabilities

The application is intentionally designed with some methods having low test coverage to showcase Code Qualia's analysis capabilities.

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

4. Analyze with Code Qualia:
   ```bash
   bundle exec code-qualia generate
   ```
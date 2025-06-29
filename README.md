# Test Sentinel

**AI-powered test coverage analysis tool for Rails applications**

Test Sentinel analyzes your codebase to identify methods that most urgently need test coverage based on code complexity, current coverage, git activity, and directory importance.

## 🎯 Key Features

- **Smart Prioritization**: Combines coverage data, code complexity, git history, and directory weights to score methods
- **Multiple Data Sources**: Integrates with SimpleCov, RuboCop, and Git
- **Configurable Weights**: Customize analysis parameters via YAML configuration
- **CLI Interface**: Easy-to-use command line tool with JSON output
- **CI/CD Ready**: GitHub Actions integration for automated analysis

## 🚀 Installation

Add this line to your application's Gemfile:

```ruby
gem 'test_sentinel', group: [:development, :test]
```

And then execute:
```bash
bundle install
```

## 📋 Usage

### Setup

First, generate a configuration file for your project:

```bash
# Auto-detect project type and generate sentinel.yml
bundle exec test-sentinel install
```

This command automatically detects whether you're working with a Rails application or a Ruby gem and generates an appropriate configuration file.

### Basic Analysis

```bash
# Analyze top 3 methods (default)
bundle exec test-sentinel generate

# Analyze top 10 methods  
bundle exec test-sentinel generate --top-n 10

# Use custom config file
bundle exec test-sentinel generate --config custom_sentinel.yml

# Output in different formats
bundle exec test-sentinel generate --format json
bundle exec test-sentinel generate --format csv
bundle exec test-sentinel generate --format table
```

### Sample Output

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

## ⚙️ Configuration

Create a `sentinel.yml` file in your project root:

```yaml
# Weights for priority score calculation
score_weights:
  coverage: 1.5      # Weight for coverage factor (higher = prioritize low coverage)
  complexity: 1.0    # Weight for complexity factor
  git_history: 0.8   # Weight for git activity
  directory: 1.2     # Weight for directory importance

# Directory-specific importance weights  
directory_weights:
  - path: "app/models/"
    weight: 1.5      # Models are critical
  - path: "app/services/"
    weight: 1.5      # Services contain business logic
  - path: "app/controllers/"
    weight: 1.0      # Standard weight

# Files to exclude from analysis
exclude:
  - "app/helpers/**/*"
  - "config/**/*"
  - "db/**/*"

# Days of git history to analyze
git_history_days: 90
```

## 🔧 Requirements

- **SimpleCov**: For test coverage data
- **RuboCop**: For code complexity analysis  
- **Git**: For file change history


## 🏗️ How It Works

Test Sentinel calculates a priority score for each method using:

**Score = (W_cov × CoverageFactor) + (W_comp × ComplexityFactor) + (W_git × GitFactor) + (W_dir × DirectoryFactor)**

Where:
- **CoverageFactor**: `(1.0 - coverage_rate)` - lower coverage = higher priority
- **ComplexityFactor**: Cyclomatic complexity from RuboCop
- **GitFactor**: Number of commits in specified time period
- **DirectoryFactor**: Weight based on file location

## 🚢 CI/CD Integration

### GitHub Actions

```yaml
name: Test Sentinel Analysis

on: [push, pull_request]

jobs:
  test_sentinel:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        bundler-cache: true
    - name: Run tests with coverage
      run: bundle exec rspec
    - name: Run Test Sentinel analysis  
      run: bundle exec test-sentinel generate --top-n 10
    - name: Upload analysis results
      uses: actions/upload-artifact@v4
      with:
        name: test-sentinel-analysis
        path: test_sentinel_analysis.json
```

## 🧪 Development

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run integration tests only
bundle exec rspec spec/integration/
```

### Smoke Testing

Test Sentinel includes a comprehensive smoke test suite that validates functionality against a sample Rails application in the `smoke/sample_app` directory.

## 📊 Output Formats

Test Sentinel supports multiple output formats for flexibility:

### Human-readable (default)
```
📊 Top 3 methods requiring test coverage:

1. app/models/user.rb:19
   Method: can_access_feature?
   Priority Score: 9.55
   Coverage: 50.0%
   Complexity: 7
   Git Commits: 0
```

### JSON Format
```json
[
  {
    "file_path": "app/models/user.rb",
    "class_name": "User", 
    "method_name": "can_access_feature?",
    "line_number": 19,
    "score": 9.55,
    "details": {
      "coverage": 0.5,
      "complexity": 7,
      "git_commits": 0
    }
  }
]
```

### CSV Format
```csv
file_path,method_name,line_number,score,coverage,complexity,git_commits
app/models/user.rb,can_access_feature?,19,9.55,50.0,7,0
```

### Table Format
```
+-------------------+----------------------+------+-------+----------+------------+----------+
| File              | Method               | Line | Score | Coverage | Complexity | Commits  |
+-------------------+----------------------+------+-------+----------+------------+----------+
| app/models/user.rb| can_access_feature?  |   19 |  9.55 |    50.0% |          7 |        0 |
+-------------------+----------------------+------+-------+----------+------------+----------+
```

All formats can be redirected to files using standard Unix redirection:
```bash
bundle exec test-sentinel generate --format json > analysis.json
bundle exec test-sentinel generate --format csv > analysis.csv
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run the test suite (`bundle exec rspec`)
5. Commit your changes (`git commit -am 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
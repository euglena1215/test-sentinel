# Code Qualia

**A tool for communicating developer intuition and code quality perception to AI through configurable parameters**

Code Qualia helps developers express their subjective understanding and feelings about code quality to AI systems. By combining quantitative metrics (coverage, complexity, git activity) with configurable weights that reflect your development priorities and intuitions, it creates a "quality fingerprint" that AI can understand and use for better code analysis and recommendations.

## 🎯 Key Features

- **Developer Intuition Translation**: Convert your subjective code quality perceptions into quantifiable parameters
- **Configurable Quality Weights**: Express what matters most to you - complexity, coverage, change frequency, or directory importance
- **AI-Ready Output**: Generate structured data that AI systems can use to understand your code priorities
- **Multiple Data Sources**: Integrates with SimpleCov, RuboCop, and Git to capture comprehensive code context
- **Flexible Interface**: CLI tool with JSON, CSV, and human-readable output formats

## 🚀 Installation

Add this line to your application's Gemfile:

```ruby
gem 'code_qualia', group: [:development, :test]
```

And then execute:
```bash
bundle install
```

## 📋 Usage

### Setup

First, generate a configuration file for your project:

```bash
# Auto-detect project type and generate qualia.yml
bundle exec code-qualia install
```

This command automatically detects whether you're working with a Rails application or a Ruby gem and generates an appropriate configuration file.

### Basic Analysis

```bash
# Analyze top 3 methods (default)
bundle exec code-qualia generate

# Analyze top 10 methods  
bundle exec code-qualia generate --top-n 10

# Use custom config file
bundle exec code-qualia generate --config custom_qualia.yml

# Output in different formats
bundle exec code-qualia generate --format json
bundle exec code-qualia generate --format csv
bundle exec code-qualia generate --format table
```

### Sample Output

```
📊 Top 3 methods requiring test coverage:

1. app/models/user.rb:21
   Method: can_access_feature?
   Priority Score: 18.6
   Coverage: 50.0%
   Complexity: 7
   Git Commits: 0

2. app/models/user.rb:35
   Method: calculate_discount
   Priority Score: 11.4
   Coverage: 50.0%
   Complexity: 4
   Git Commits: 0

3. packs/users/app/models/users/user_profile.rb:5
   Method: display_name
   Priority Score: 7.8
   Coverage: 0.0%
   Complexity: 5
   Git Commits: 0
```

## ⚙️ Configuration

Create a `qualia.yml` file in your project root:

```yaml
# Quality indicators (code issues that need fixing)
quality_weights:
  test_coverage: 1.5          # Weight for test coverage (lower coverage = higher priority)
  cyclomatic_complexity: 1.0  # Weight for cyclomatic complexity (higher complexity = higher priority)

# Importance indicators (how critical the code is)
importance_weights:
  change_frequency: 0.8         # Weight for git change frequency (more changes = higher importance)
  architectural_importance: 1.2 # Weight for architectural importance (critical paths = higher importance)

# Path-based architectural importance weights
architectural_weights:
  - path: "app/models/**/*.rb"
    weight: 2.0      # Models are critical for business logic
  - path: "app/services/**/*.rb"
    weight: 1.8      # Services contain complex business logic
  - path: "app/controllers/**/*.rb"
    weight: 1.5      # Controllers handle user interactions
  - path: "lib/**/*.rb"
    weight: 1.0      # Library code standard weight

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

Code Qualia calculates a priority score for each method using a multiplicative approach that separates quality issues from code importance:

**FinalScore = QualityScore × ImportanceScore**

Where:
- **QualityScore** = `(W_test_coverage × TestCoverageFactor) + (W_cyclomatic_complexity × ComplexityFactor)`
- **ImportanceScore** = `(W_change_frequency × ChangeFrequencyFactor) + (W_architectural_importance × ArchitecturalFactor)`

**Quality Indicators** (code issues that need fixing):
- **TestCoverageFactor**: `(1.0 - coverage_rate)` - lower coverage = higher quality risk
- **ComplexityFactor**: Cyclomatic complexity from RuboCop - higher complexity = higher quality risk

**Importance Indicators** (how critical the code is):
- **ChangeFrequencyFactor**: Number of commits in specified time period - more changes = higher importance
- **ArchitecturalFactor**: Weight based on file location (configurable) - critical paths = higher importance

This approach ensures that both quality issues AND importance must be present for a method to rank highly, providing more logical prioritization.


## 🧪 Development

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run integration tests only
bundle exec rspec spec/integration/
```

### Smoke Testing

Code Qualia includes a comprehensive smoke test suite that validates functionality against a sample Rails application in the `smoke/sample_app` directory.

## 📊 Output Formats

Code Qualia supports multiple output formats for flexibility:

### Human-readable (default)
```
📊 Top 3 methods requiring test coverage:

1. app/models/user.rb:21
   Method: can_access_feature?
   Priority Score: 10.15
   Coverage: 50.0%
   Complexity: 7
   Git Commits: 0

2. packs/users/app/models/users/user_profile.rb:5
   Method: display_name
   Priority Score: 7.7
   Coverage: 0.0%
   Complexity: 5
   Git Commits: 0
```

### JSON Format
```json
[
  {
    "file_path": "app/models/user.rb",
    "class_name": "User",
    "method_name": "can_access_feature?",
    "line_number": 21,
    "score": 10.15,
    "details": {
      "coverage": 0.5,
      "complexity": 7,
      "git_commits": 0
    }
  },
  {
    "file_path": "packs/users/app/models/users/user_profile.rb",
    "class_name": "UserProfile",
    "method_name": "display_name",
    "line_number": 5,
    "score": 7.7,
    "details": {
      "coverage": 0.0,
      "complexity": 5,
      "git_commits": 0
    }
  }
]
```

### CSV Format
```csv
file_path,method_name,line_number,score,coverage,complexity,git_commits
app/models/user.rb,can_access_feature?,21,10.15,50.0,7,0
packs/users/app/models/users/user_profile.rb,display_name,5,7.7,0.0,5,0
```

### Table Format
```
+----------------------------------------------+---------------------+------+-------+----------+------------+----------+
| File                                         | Method              | Line | Score | Coverage | Complexity | Commits  |
+----------------------------------------------+---------------------+------+-------+----------+------------+----------+
| app/models/user.rb                           | can_access_feature? |   21 | 10.15 |    50.0% |          7 |        0 |
| packs/users/app/models/users/user_profile.rb | display_name        |    5 |  7.70 |     0.0% |          5 |        0 |
+----------------------------------------------+---------------------+------+-------+----------+------------+----------+
```

All formats can be redirected to files using standard Unix redirection:
```bash
bundle exec code-qualia generate --format json > analysis.json
bundle exec code-qualia generate --format csv > analysis.csv
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

This project is licensed under the MIT License.
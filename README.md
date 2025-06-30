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

3. app/models/user.rb:35
   Method: calculate_discount
   Priority Score: 7.15
   Coverage: 50.0%
   Complexity: 4
   Git Commits: 0
```

## ⚙️ Configuration

Create a `qualia.yml` file in your project root:

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

Code Qualia calculates a priority score for each method using:

**Score = (W_cov × CoverageFactor) + (W_comp × ComplexityFactor) + (W_git × GitFactor) + (W_dir × DirectoryFactor)**

Where:
- **CoverageFactor**: `(1.0 - coverage_rate)` - lower coverage = higher priority
- **ComplexityFactor**: Cyclomatic complexity from RuboCop
- **GitFactor**: Number of commits in specified time period
- **DirectoryFactor**: Weight based on file location


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
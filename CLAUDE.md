# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Code Qualia is an AI-powered test coverage analysis tool for Rails applications that identifies methods most urgently needing test coverage. It combines SimpleCov coverage data, RuboCop complexity analysis, git history, and configurable directory weights to calculate priority scores for methods.

## Common Commands

### Development Commands
```bash
# Install dependencies
bundle install

# Run all tests
bundle exec rspec

# Run unit tests only
bundle exec rspec spec/unit/

# Run integration tests only
bundle exec rspec spec/integration/

# Run a specific test file
bundle exec rspec spec/unit/complexity_analyzer_spec.rb

# Run code formatting
bundle exec rubocop --autocorrect
bundle exec rubocop -A  # Aggressive auto-correction

# Generate coverage report
bundle exec rspec  # SimpleCov runs automatically with tests
```

### Code Qualia Commands
```bash
# Basic analysis (top 3 methods)
bundle exec code-qualia generate

# Analyze top 10 methods
bundle exec code-qualia generate --top-n 10

# Use custom config file
bundle exec code-qualia generate --config custom_qualia.yml

# Analyze a different directory
bundle exec code-qualia generate --directory /path/to/project --top-n 5
```

### Smoke Testing
The project includes a sample Rails app in `smoke/sample_app` for testing:
```bash
cd smoke/sample_app
bundle exec rspec  # Generate coverage data
cd ../..
bundle exec code-qualia generate --directory ./smoke/sample_app --top-n 10
```

## Architecture

### Core Analysis Pipeline
Code Qualia follows a 4-stage analysis pipeline orchestrated by `CodeQualia.analyze()`:

1. **Coverage Analysis** (`CoverageAnalyzer`) - Parses SimpleCov's `.resultset.json` to extract line-by-line coverage data
2. **Complexity Analysis** (`ComplexityAnalyzer`) - Executes RuboCop to get cyclomatic complexity metrics
3. **Git History Analysis** (`GitAnalyzer`) - Analyzes git log to count file changes over configurable time period
4. **Score Calculation** (`ScoreCalculator`) - Combines all data sources using weighted formula to rank methods

### Scoring Algorithm
The priority score uses a multiplicative formula that separates quality indicators from importance indicators:
```
FinalScore = QualityScore × ImportanceScore

QualityScore = (W_test_coverage × TestCoverageFactor) + (W_cyclomatic_complexity × ComplexityFactor)
ImportanceScore = (W_change_frequency × ChangeFrequencyFactor) + (W_architectural_importance × ArchitecturalFactor)
```

Where:
**Quality Indicators** (code issues that need fixing):
- `TestCoverageFactor`: `(1.0 - coverage_rate)` - lower coverage = higher quality risk
- `ComplexityFactor`: Cyclomatic complexity from RuboCop - higher complexity = higher quality risk

**Importance Indicators** (how critical the code is):
- `ChangeFrequencyFactor`: Number of commits in specified time period - more changes = higher importance
- `ArchitecturalFactor`: Weight based on file location (configurable) - critical paths = higher importance

This approach ensures that both quality issues AND importance must be present for a method to rank highly.

### Key Components

**Main Entry Point**: `lib/code_qualia.rb` - Coordinates the analysis pipeline

**Data Analyzers**:
- `CoverageAnalyzer`: Parses SimpleCov data, supports both `app/` and `lib/` directories
- `ComplexityAnalyzer`: Executes RuboCop with JSON output, extracts method complexity
- `GitAnalyzer`: Runs git log commands, counts file changes over time

**Processing**:
- `ScoreCalculator`: Implements the weighted scoring algorithm, extracts methods from Ruby files
- `ScenarioGenerator`: Analyzes method code to suggest test scenarios (parses if/case statements)
- `Config`: Loads and validates YAML configuration files

**CLI**: `bin/code-qualia` - Command-line interface with OptionParser

### Configuration System
Uses YAML configuration files (default: `qualia.yml`) to control:
- Score weights for different factors
- Directory-specific importance weights
- File exclusion patterns
- Git history analysis period

### Testing Strategy
- **Unit Tests**: Located in `spec/unit/`, test individual analyzer components with mocked dependencies
- **Integration Tests**: Located in `spec/integration/`, use the smoke test Rails app for end-to-end validation
- **Smoke Tests**: Compare actual CLI output against expected results stored in `expected_outputs/`

### File Path Handling
The analyzers normalize file paths to relative paths starting with `app/` or `lib/` for consistency across different execution contexts. This allows Code Qualia to analyze both Rails apps (with `app/` directories) and Ruby gems (with `lib/` directories).

### Error Handling
Custom `CodeQualia::Error` class provides structured error handling throughout the pipeline. Each analyzer rescues and re-raises errors with context about which analysis phase failed.

## Configuration

Code Qualia uses `qualia.yml` for configuration. Key sections:
- `quality_weights`: Controls weights for code quality indicators (test_coverage, cyclomatic_complexity)
- `importance_weights`: Controls weights for code importance indicators (change_frequency, architectural_importance)
- `architectural_weights`: Path-based multipliers for different code areas (formerly directory_weights)
- `exclude`: File patterns to skip during analysis
- `git_history_days`: Time window for git analysis (default: 90 days)

Example configuration:
```yaml
quality_weights:
  test_coverage: 1.5
  cyclomatic_complexity: 1.0

importance_weights:
  change_frequency: 0.8
  architectural_importance: 1.2

architectural_weights:
  - path: 'app/models/**/*.rb'
    weight: 2.0
  - path: 'app/controllers/**/*.rb'
    weight: 1.5
```

## Development Notes

- The tool prioritizes deterministic analysis over AI-based heuristics for method identification
- Supports analyzing any Ruby project with `app/` or `lib/` directories, not just Rails
- CLI includes `--directory` option to analyze projects outside the current directory
- SimpleCov coverage data is required; tests must be run first to generate `.resultset.json`
- RuboCop must be available (tries `bundle exec rubocop` first, falls back to `rubocop`)

## Development Workflow

**CRITICAL**: Always run tests after making any code changes:
```bash
bundle exec rspec
```
- ALL tests must pass before proceeding to the next task
- Never move to the next work item if tests are failing
- Fix any failing tests immediately after making changes

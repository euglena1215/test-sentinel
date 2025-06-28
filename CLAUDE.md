# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Test Sentinel is an AI-powered test coverage analysis tool for Rails applications that identifies methods most urgently needing test coverage. It combines SimpleCov coverage data, RuboCop complexity analysis, git history, and configurable directory weights to calculate priority scores for methods.

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

### Test Sentinel Commands
```bash
# Basic analysis (top 3 methods)
bundle exec test-sentinel generate

# Analyze top 10 methods
bundle exec test-sentinel generate --top-n 10

# Use custom config file
bundle exec test-sentinel generate --config custom_sentinel.yml

# Analyze a different directory
bundle exec test-sentinel generate --directory /path/to/project --top-n 5
```

### Smoke Testing
The project includes a sample Rails app in `smoke/sample_app` for testing:
```bash
cd smoke/sample_app
bundle exec rspec  # Generate coverage data
cd ../..
bundle exec test-sentinel generate --directory ./smoke/sample_app --top-n 10
```

## Architecture

### Core Analysis Pipeline
Test Sentinel follows a 4-stage analysis pipeline orchestrated by `TestSentinel.analyze()`:

1. **Coverage Analysis** (`CoverageAnalyzer`) - Parses SimpleCov's `.resultset.json` to extract line-by-line coverage data
2. **Complexity Analysis** (`ComplexityAnalyzer`) - Executes RuboCop to get cyclomatic complexity metrics  
3. **Git History Analysis** (`GitAnalyzer`) - Analyzes git log to count file changes over configurable time period
4. **Score Calculation** (`ScoreCalculator`) - Combines all data sources using weighted formula to rank methods

### Scoring Algorithm
The priority score uses this weighted formula:
```
Score = (W_cov × CoverageFactor) + (W_comp × ComplexityFactor) + (W_git × GitFactor) + (W_dir × DirectoryFactor)
```

Where:
- `CoverageFactor`: `(1.0 - coverage_rate)` - lower coverage = higher priority
- `ComplexityFactor`: Cyclomatic complexity from RuboCop
- `GitFactor`: Number of commits in specified time period  
- `DirectoryFactor`: Weight based on file location (configurable)

### Key Components

**Main Entry Point**: `lib/test_sentinel.rb` - Coordinates the analysis pipeline

**Data Analyzers**:
- `CoverageAnalyzer`: Parses SimpleCov data, supports both `app/` and `lib/` directories
- `ComplexityAnalyzer`: Executes RuboCop with JSON output, extracts method complexity
- `GitAnalyzer`: Runs git log commands, counts file changes over time

**Processing**:
- `ScoreCalculator`: Implements the weighted scoring algorithm, extracts methods from Ruby files
- `ScenarioGenerator`: Analyzes method code to suggest test scenarios (parses if/case statements)
- `Config`: Loads and validates YAML configuration files

**CLI**: `bin/test-sentinel` - Command-line interface with OptionParser

### Configuration System
Uses YAML configuration files (default: `sentinel.yml`) to control:
- Score weights for different factors
- Directory-specific importance weights
- File exclusion patterns
- Git history analysis period

### Testing Strategy
- **Unit Tests**: Located in `spec/unit/`, test individual analyzer components with mocked dependencies
- **Integration Tests**: Located in `spec/integration/`, use the smoke test Rails app for end-to-end validation
- **Smoke Tests**: Compare actual CLI output against expected results stored in `expected_outputs/`

### File Path Handling
The analyzers normalize file paths to relative paths starting with `app/` or `lib/` for consistency across different execution contexts. This allows Test Sentinel to analyze both Rails apps (with `app/` directories) and Ruby gems (with `lib/` directories).

### Error Handling
Custom `TestSentinel::Error` class provides structured error handling throughout the pipeline. Each analyzer rescues and re-raises errors with context about which analysis phase failed.

## Configuration

Test Sentinel uses `sentinel.yml` for configuration. Key sections:
- `score_weights`: Controls relative importance of coverage, complexity, git history, and directory factors
- `directory_weights`: Path-based multipliers for different code areas  
- `exclude`: File patterns to skip during analysis
- `git_history_days`: Time window for git analysis (default: 90 days)

## Development Notes

- The tool prioritizes deterministic analysis over AI-based heuristics for method identification
- Supports analyzing any Ruby project with `app/` or `lib/` directories, not just Rails
- CLI includes `--directory` option to analyze projects outside the current directory
- SimpleCov coverage data is required; tests must be run first to generate `.resultset.json`
- RuboCop must be available (tries `bundle exec rubocop` first, falls back to `rubocop`)
# Gemini Development Guidelines for code-qualia

This document outlines the conventions and guidelines for developing the `code-qualia` project with Gemini.

## Project Overview

`code-qualia` is an AI-powered test coverage analysis tool for Rails applications. It analyzes the codebase to identify methods that most urgently need test coverage based on code complexity, current coverage, git activity, and directory importance.

## Common Commands

### Development
```bash
# Install dependencies
bundle install

# Run all tests
bundle exec rspec

# Run only unit tests
bundle exec rspec spec/unit/

# Run only integration tests
bundle exec rspec spec/integration/

# Run RuboCop for linting and formatting
bundle exec rubocop -A
```

### Running the Tool
```bash
# Analyze the top 3 methods
bundle exec code-qualia generate

# Analyze the top 10 methods
bundle exec code-qualia generate --top-n 10

# Analyze a different directory
bundle exec code-qualia generate --directory ./smoke/sample_app --top-n 5
```

## Architecture

The core logic resides in `lib/code_qualia/`. The analysis pipeline is as follows:

1.  **`CoverageAnalyzer`**: Parses `simplecov`'s `.resultset.json`.
2.  **`ComplexityAnalyzer`**: Uses `rubocop` to get cyclomatic complexity.
3.  **`GitAnalyzer`**: Analyzes `git log` to count file changes.
4.  **`ScoreCalculator`**: Combines the data from the analyzers to rank methods.

The main entry point that orchestrates this pipeline is `lib/code_qualia.rb`.

## Testing Strategy

-   **Unit Tests**: Located in `spec/unit/`. These test individual components in isolation, using mocks where necessary.
-   **Integration Tests**: Located in `spec/integration/`. These tests run the tool against the sample Rails app in `smoke/sample_app` to ensure end-to-end functionality.
-   **Smoke Tests**: The integration tests also serve as smoke tests, comparing the CLI output against expected results in `expected_outputs/`.

## Development Guidelines

### Code Style and Conventions

-   **Language**: Ruby
-   **Linter**: RuboCop. Adhere to the existing `.rubocop.yml` configuration. Run `bundle exec rubocop -A` before committing.
-   **Testing**: RSpec. All new features or bug fixes must have corresponding tests.

### Commit Messages

-   Write commit messages in concise, imperative English.
-   Examples: `Fix gemspec`, `Implement feature`, `Add design.md`

### Dependencies

-   Manage dependencies using `Gemfile` and Bundler.
-   Do not add new dependencies without prior discussion.

### Workflow

1.  **Understand the Goal**: Before making changes, thoroughly understand the user's request and the relevant project context.
2.  **Write/Update Tests**: For any code change, first write or update the necessary RSpec tests.
3.  **Implement the Change**: Write the code to make the tests pass.
4.  **Run Linters and Tests**: Before committing, run `bundle exec rubocop -A` and `bundle exec rspec` to ensure all checks pass.
5.  **Commit**: Write a clear and concise commit message following the established convention.
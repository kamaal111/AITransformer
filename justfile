set dotenv-load

# List available commands
default:
    just --list --unsorted

# Lint project
lint:
    swiftlint

# Auto fix auto-fixable linting errors project
lint-fix:
    swiftlint --fix

# Bootstrap project
bootstrap:
    brew install swiftlint

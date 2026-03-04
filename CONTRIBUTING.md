# Contributing

Thanks for your interest in contributing to Superthread!

## Getting Started

```bash
git clone https://github.com/steveclarke/superthread.git
cd superthread
bundle install
```

## Running Tests

```bash
bundle exec rspec
```

## Code Style

This project uses [StandardRB](https://github.com/standardrb/standard). After making changes:

```bash
bundle exec standardrb --fix
```

## Documentation

YARD docs are linted with [yard-lint](https://github.com/mensfeld/yard-lint):

```bash
bundle exec yard-lint lib/
```

## Pre-commit Hooks

[Lefthook](https://github.com/evilmartians/lefthook) runs StandardRB and yard-lint automatically on staged files before each commit. Install it with:

```bash
brew install lefthook
lefthook install
```

## Before Making Big Changes

Please open an issue first so we can discuss the approach before you invest significant time.

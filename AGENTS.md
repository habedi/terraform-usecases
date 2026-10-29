# AGENTS.md

This file provides guidance to coding agents collaborating on this repository.

## Mission

This repository contains a collection of Terraform use cases provisioning resources in AWS to set up environments for various infrastructure and application scenarios.

The priority order of tasks is defined below.

1. Correctness, idempotency, and security of Terraform configurations.
2. Complete and accurate documentation for provisioning and tearing down each use case.
3. Standard-compliant resource definitions following AWS provider best practices.
4. Clean dependency and development environment management using uv and Nix.

## Core Rules

- Use English for code, comments, documentation, and commit messages.
- Prefer small, focused changes over broad refactoring.
- Add comments only when they clarify non-obvious behavior or AWS-specific nuances.
- Do not add external tools, providers, or abstractions beyond what is needed for the current task.
- Follow Terraform conventions: format with `terraform fmt`, validate with `terraform validate`, and pin provider versions.
- Never hardcode or commit credentials, sensitive secrets, or state files.

## Writing Style

- Use Oxford commas in inline lists, such as "a, b, and c" instead of "a, b, c".
- Do not use em dashes. Restructure the sentence, or use a semicolon or period instead.
- Avoid colorful adjectives and adverbs, writing "server deployment" instead of "robust server deployment".
- Prefer using noun phrases for checklist items instead of imperative verbs, such as writing "variable validation" instead of "validate variables".
- Write headings in markdown files in title case, for example, "Provision a Server" instead of "Provision a server". Minor words (a, an, the, and, but, or, for, in, on, at, to, by, of, from, and with) stay lowercase unless they are the first word.
- Write correct and complete sentences.
- Avoid made-up words, abbreviations, and colons in the middle of sentences.
- Do not use pretentious language.

## Repository Layout

- `use-cases/` for individual use case implementations.
  - `use-cases/use-case-1/` for provisioning a single server and networking resources.
  - `use-cases/use-case-2/` for provisioning a server and an RDS database instance.
  - `use-cases/use-case-3/` for setting up a GraphQL API with AWS AppSync and RDS Aurora.
- `use-cases/*/main.tf` for primary resource definitions.
- `use-cases/*/variables.tf` for input variable declarations, types, and descriptions.
- `use-cases/*/outputs.tf` for output definitions.
- `use-cases/*/versions.tf` for required Terraform and AWS provider versions.
- `use-cases/*/README.md` for deployment and architecture instructions for each use case.
- `pyproject.toml` for Python project configuration and dependency management using uv.
- `uv.lock` for deterministic Python dependency versions.
- `.python-version` for the pinned Python version.
- `Makefile` for script runner definitions for development tasks.
- `tests/` for validation test cases.
- `flake.nix` for the Nix development shell definition.
- `README.md` for project overview and use case indexing.

## Terraform Conventions

- Formatting using `terraform fmt -check -recursive`.
- Syntax and configuration validation using `terraform validate`.
- Explicit specification of variable types, default values where appropriate, and descriptions in `variables.tf`.
- Output documentation in `outputs.tf` for exported infrastructure properties.
- Provider requirements pinned in `versions.tf`.

## Python Conventions

- Python version `>=3.10` declared in package configuration.
- Dependency management using uv.
- Execution of commands using `uv run`.

## Required Validation

Run the relevant targets for any change:

| Target           | Command                             | What It Runs                                          |
|------------------|-------------------------------------|-------------------------------------------------------|
| Format check     | `terraform fmt -check -recursive`   | Checks Terraform configuration format across modules. |
| Formatting       | `terraform fmt -recursive`          | Applies automatic Terraform style alignment.          |
| Module check     | `terraform validate`                | Validates syntax and configuration in a module.       |
| Dependency check | `uv sync --locked`                  | Verifies Python environment and lockfile consistency. |

## Change Design Checklist

### Before Coding

1. Identification of target use cases and affected modules.
2. Definition of required AWS resources, inputs, and outputs.
3. Verification of security group rules, network boundaries, and IAM policies.
4. Backward compatibility check.

### Before Submitting

1. Success status for Terraform formatting alignment via `terraform fmt`.
2. Validation status via `terraform validate` in modified use case directories.
3. Documentation alignment in the relevant `README.md` files.
4. Clean status for Python dependencies via `uv sync --locked`.

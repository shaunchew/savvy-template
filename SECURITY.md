# Security Policy

## Supported versions

Only the latest release of the `sf` plugin / template is supported.

## Reporting a vulnerability

Email **scwj1210@gmail.com** with the details, or use GitHub's private
vulnerability reporting on this repository. Please do not open a public issue.

You can expect an acknowledgement within 72 hours.

## Scope notes for this project

The framework executes shell hooks inside users' Claude Code sessions and
seeds files into users' repositories. Reports of particular interest:

- Hook scripts (`hooks/*.sh`) that can be made to execute attacker-controlled
  input (e.g. via crafted tool payloads on stdin).
- `/sf:adopt` / migration paths that can overwrite or delete user files
  outside the documented contract.
- The secret-scan hook failing to block a class of credentials it claims to
  cover, or being trivially bypassable.
- Prompt-injection vectors in commands/skills that could steer an LLM into
  destructive actions in an adopted project.

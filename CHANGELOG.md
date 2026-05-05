# Changelog

All notable changes to this research prototype will be documented in this file.

## [0.1.0] - 2026-05-05

### Added

- LLM provider adapter supporting Claude, Codex, Ollama, custom commands, and OpenAI-compatible APIs.
- Tests for the LLM provider adapter.
- SQLite trigger to reject proposal self-votes by the proposing agent.
- SQLite trigger to reject artifact self-reviews by the artifact author.
- Tests covering proposal self-vote and artifact self-review rejection.
- Research-facing technical report draft under `paper/technical-report.md`.
- Research questions, evaluation plan, experiment log template, figures, related-work notes, and Zenodo release checklist under `paper/`.
- Citation metadata in `CITATION.cff`.
- Zenodo metadata draft in `.zenodo.json`.
- MIT license.
- README research sections covering motivation, architecture, reproducibility, evaluation, citation, limitations, and roadmap.

### Notes

- This release is intended as a technical-report / working-paper package.
- It should not be described as peer-reviewed.
- Controlled baseline experiments remain future work.

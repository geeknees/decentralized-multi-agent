# Research Notes and Technical Report

This directory contains the research materials for the decentralized multi-agent prototype. The repository remains the implementation workspace. This directory keeps the technical-report framing, research questions, evaluation plan, and Zenodo release notes.

This is a working-paper package, not a peer-reviewed publication. Unless a result is explicitly reported, read the claims as implementation-grounded observations or hypotheses.

## Contents

| File | Purpose |
|---|---|
| `technical-report.md` | Draft technical report for DOI-bearing Zenodo release |
| `research-questions.md` | Research questions, observable indicators, and current claim boundaries |
| `evaluation-plan.md` | Metrics, baselines, and experiment design |
| `experiment-log-template.md` | Per-run experiment logging template |
| `figures.md` | Mermaid diagrams for architecture, loops, decision flow, artifact review, and schema |
| `related-work-notes.md` | Attachment-style notes separating required reading from candidate related work |
| `zenodo-release-checklist.md` | Release checklist for GitHub and Zenodo |

## Suggested Release Package

For a v0.1.0 Zenodo archive, include:

- source code and tests;
- `README.md`, `LICENSE`, `CITATION.cff`, `.zenodo.json`, and `CHANGELOG.md`;
- all files under `paper/`;
- one sample mission definition and, if available, a sanitized sample run log.

Do not treat generated runtime files such as `db/*.db`, `whole_conversation_doc.md`, or `peer_review_doc.md` as canonical unless they have been copied into a versioned sample directory with reproducibility notes.

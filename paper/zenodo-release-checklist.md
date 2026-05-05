# Zenodo Release Checklist

Use this checklist before creating a GitHub release connected to Zenodo.

## Repository State

- [x] Working tree reviewed for unrelated files and local runtime artifacts.
- [x] Version tag selected, e.g. `v0.1.0`.
- [x] `CHANGELOG.md` updated for the selected version.
- [x] `README.md` includes research motivation, architecture, reproducibility, limitations, and citation guidance.
- [x] `LICENSE` checked and compatible with intended release.
- [x] `CITATION.cff` validates and matches the release version.
- [x] `.zenodo.json` metadata checked.

## Tests and Reproducibility

- [x] Tests pass on the release commit.
- [x] Proposal self-vote prevention verified.
- [x] Artifact self-review prevention verified.
- [x] Test output is clean enough to archive or quote.
- [x] Sample mission included or referenced.
- [x] Fresh sample run created with the current schema.
- [x] Sample run includes exported conversation and peer-review logs.
- [x] Experiment log completed from `paper/experiment-log-template.md`.
- [x] Git commit hash recorded in the sample run metadata.
- [x] Model/provider and date recorded.

## Research Package

- [x] `paper/technical-report.md` included.
- [x] `paper/research-questions.md` included.
- [x] `paper/evaluation-plan.md` included.
- [x] `paper/experiment-log-template.md` included.
- [x] `paper/figures.md` included.
- [x] `paper/related-work-notes.md` included.
- [x] Limitations reviewed for accuracy and restraint.
- [x] Claims checked against implementation and sample logs.
- [x] Candidate related work kept out of formal references unless directly connected to the report.

## Archive Contents

- [x] Runtime databases excluded unless intentionally archived as sample data.
- [x] Generated logs excluded unless intentionally curated as sample data.
- [x] API keys, credentials, personal notes, and local `.DS_Store` files excluded.
- [ ] Archive contents reviewed before release.

## GitHub and Zenodo

- [x] GitHub release created for the version tag.
- [x] Zenodo DOI reserved or minted.
- [x] Zenodo metadata reviewed before publishing.
- [x] DOI linked back from `README.md`.
- [x] GitHub repository URL linked from Zenodo.
- [x] Release notes state that this is a working-paper / technical-report release, not a peer-reviewed paper.

## Human Review Before Publishing

- [x] Author name and affiliation verified.
- [x] License decision verified.
- [x] Abstract approved.
- [x] Keywords approved.
- [x] Required related-work references checked for citation accuracy.
- [x] Any sample artifact checked for factual claims and source quality.

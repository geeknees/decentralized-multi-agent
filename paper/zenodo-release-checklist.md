# Zenodo Release Checklist

Use this checklist before creating a GitHub release connected to Zenodo.

## Repository State

- [ ] Working tree reviewed for unrelated files and local runtime artifacts.
- [ ] Version tag selected, e.g. `v0.1.0`.
- [ ] `CHANGELOG.md` updated for the selected version.
- [ ] `README.md` includes research motivation, architecture, reproducibility, limitations, and citation guidance.
- [ ] `LICENSE` checked and compatible with intended release.
- [ ] `CITATION.cff` validates and matches the release version.
- [ ] `.zenodo.json` metadata checked.

## Tests and Reproducibility

- [ ] Tests pass on the release commit.
- [ ] Proposal self-vote prevention verified.
- [ ] Artifact self-review prevention verified.
- [ ] Test output is clean enough to archive or quote.
- [ ] Sample mission included or referenced.
- [ ] Fresh sample run created with the current schema.
- [ ] Sample run includes exported conversation and peer-review logs.
- [ ] Experiment log completed from `paper/experiment-log-template.md`.
- [ ] Git commit hash recorded in the sample run metadata.
- [ ] Model/provider and date recorded.

## Research Package

- [ ] `paper/technical-report.md` included.
- [ ] `paper/research-questions.md` included.
- [ ] `paper/evaluation-plan.md` included.
- [ ] `paper/experiment-log-template.md` included.
- [ ] `paper/figures.md` included.
- [ ] `paper/related-work-notes.md` included.
- [ ] Limitations reviewed for accuracy and restraint.
- [ ] Claims checked against implementation and sample logs.
- [ ] Unverified citations marked as TODO or "to verify".

## Archive Contents

- [ ] Runtime databases excluded unless intentionally archived as sample data.
- [ ] Generated logs excluded unless intentionally curated as sample data.
- [ ] API keys, credentials, personal notes, and local `.DS_Store` files excluded.
- [ ] Archive contents reviewed before release.

## GitHub and Zenodo

- [ ] GitHub release created for the version tag.
- [ ] Zenodo DOI reserved or minted.
- [ ] Zenodo metadata reviewed before publishing.
- [ ] DOI linked back from `README.md`.
- [ ] GitHub repository URL linked from Zenodo.
- [ ] Release notes state that this is a working-paper / technical-report release, not a peer-reviewed paper.

## Human Review Before Publishing

- [ ] Author name and affiliation verified.
- [ ] License decision verified.
- [ ] Abstract approved.
- [ ] Keywords approved.
- [ ] Related-work notes checked for citation accuracy.
- [ ] Any sample artifact checked for factual claims and source quality.

# Project instructions

Read [Project requirements](docs/requirements.md) and [Technical decisions](docs/technical-decisions.md) before changing the application.

For every feature addition or enhancement, update both documents in the same change. Record observable behavior, scope, and acceptance criteria in the requirements. Record implementation choices, rationale, trade-offs, and any API or configuration changes in the technical decisions. Add follow-up entries when a decision changes and link related requirement IDs.

For backend changes, follow routes → controllers → services → repositories. Keep Mongoose queries in repositories and add a repository when the feature needs data access.

For Flutter changes, place feature-specific UI in `lib/features/<feature>/presentation/` and feature repositories and models in `lib/features/<feature>/data/`. Keep shared network transport in `lib/core/network/` and wire dependencies in `lib/app/`.

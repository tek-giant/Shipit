# Branching strategy

We use trunk-based development with short-lived feature branches.

- main stays deployable.
- Work happens on feature/SHIP-123-short-desc or hotfix/SHIP-456-desc.
- Changes require a pull request, one approval, and passing CI checks.
- Pull requests are squash merged.
- Direct pushes and force pushes to main are blocked.
- Commit messages use conventional prefixes and a Jira key:
  feat: SHIP-123 add health endpoint
- Releases use annotated semantic version tags, such as v1.0.0.

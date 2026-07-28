# Contributing

## Always commit and push every change

Whenever you make a change to this repository, commit it and push it to
`origin/main` right away. Do not leave work uncommitted or unpushed.

- Stage everything (`git add -A`), commit with a clear message, and `git push`.
- Do this after each meaningful change, not in one big batch at the end.
- The live site redeploys from `main`, so pushing keeps the deployed build in
  sync with the source.

## Scope gameplay fixes before changing code

Before implementing a gameplay or UI behavior fix, diagnose whether the problem
is universal, singleplayer-only, or multiplayer-only. Apply the change only to
the matching workflow unless the same root cause is proven in both modes. Tests
should exercise the affected workflow directly, such as New Game for local-only
issues or Create/Join Lobby for online multiplayer issues.

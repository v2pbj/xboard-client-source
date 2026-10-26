# Fork notice

This repository is a **modified fork of [FlClash](https://github.com/chen08209/FlClash)** by
chen08209, used as the client for a self-hosted Xboard panel.

## What this fork changes

- App identity: display name, Android application id, URL scheme, Windows/Linux product
  resources. The rewritten values are the ones `tool/rebrand.dart` sets.
- `lib/providers/panel_account.dart` and `lib/views/account.dart`: signing in to a panel and
  importing the subscription it returns, reached from the settings page.
- The subscription request asks for the Clash template explicitly (`flag=clash`) instead of
  relying on the User-Agent the panel sees.

Nothing was removed from the upstream client, and no feature was made unavailable.

## License

This fork, like upstream FlClash, is licensed under the **GNU General Public License v3.0**
(see `LICENSE`). Because this is a modified version, GPLv3 §5(a) requires that it carry a
notice of the modification and its date, and §6 requires that everyone who receives a built
package can also obtain the complete corresponding source of exactly that build:

- Source: the repository this notice lives in, at the commit the build was made from.
- Builds must not restrict installing or running a modified version (§6).

Upstream names and logos are not covered by the GPL and are therefore not used here: the
fork ships under its own name, its own icon and its own application id.

## Upstream

- Original project: <https://github.com/chen08209/FlClash>
- Upstream license text and copyright notices are kept unmodified in `LICENSE`.

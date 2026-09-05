# Bloodright — Isabelle’s Codex Terra Brief

Bloodright is the game. Varenza is a family surname, not the world name.

## Your workspace

Work only inside the permanent local folder:

`%USERPROFILE%\Desktop\Bloodright`

Do not move, rename, or create a second copy of the project. The folder is a
Git workspace connected to the private Bloodright repository.

## Starting the game

Double-click `Start Bloodright Debug.bat`. It opens the game maximized only
after it has fetched and installed the newest verified GitHub `main` build.
It does not launch an unverified local copy. Any unpushed local work is kept
as recovery history before master becomes the active version.

For the Godot editor, open `project.godot` and use **Run Project**.

## Building the world

Use the top navigation in Bloodright:

- **Terrain** — terrain definitions such as walls, floors, doors, and ground.
- **Items** — equipment, consumables, and objects.
- **Descriptions** — reusable visual entries. Every entry begins with a name
  and symbol, then has a description, tag ID, type, symbol size, colour, and
  visual thumbnail.
- **Maps** — map content and the First Vault’s data foundation.
- **Push** — publish the completed session safely to `main`.

Use descriptive stable IDs such as `bloodright.creature.fire_dragon`. Use tag
IDs to group content, for example `creature.dragon.fire` or
`prop.document.letter`.

Edit source content in `content/source`. Do not manually edit
`content/published/content.json`; it is generated from the source files.

## Working with Codex Terra

At the beginning of every new Codex Terra task, paste this:

> Work only in `%USERPROFILE%\Desktop\Bloodright`, the permanent private
> Git workspace. Bloodright is the game; Varenza is a family surname. Inspect
> the relevant existing files before changing anything. Preserve unrelated
> work. Keep world data in `content/source`, not in generated published data.
> Validate and test every implementation. Do not push, reset, move the
> workspace, or make an external change unless I explicitly ask. Explain the
> completed change in plain language and name the files changed.

Give Codex Terra focused requests, for example:

> Add a new Bloodright description entry for a frost wolf: a large pale `w`,
> type `character`, tag `creature.wolf.frost`, with a short lore description.
> Validate the content and keep all changes data-driven.

Ask it to:

1. Inspect the relevant existing content before editing.
2. Keep changes inside this Bloodright folder.
3. Preserve existing work that is unrelated to the request.
4. Validate and test after changes.
5. Explain exactly what changed in plain language.
6. Use **Push** only when you say the session is ready to publish.

Descriptions and application settings save locally as they are changed in the
editor. The **Push** page is still the point at which those saved changes are
validated, committed, and sent to master.

## Publishing a completed session

Open **Push** and select **Push Current Changes to Main**. It will:

1. Publish content.
2. Run tests.
3. Commit the current local work.
4. Push it to the private GitHub `main` branch.

The page reports each live stage and stops if validation or tests fail.

## Background updates and Windows notifications

After the project is cloned on Isabelle’s computer, run this once in
PowerShell from the project folder:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\install-background-updater.ps1
```

It checks GitHub every 15 minutes while she is signed in. It never overwrites
uncommitted local edits. It shows a Windows notification when a newer build is
installed or waiting, including a **Restart Bloodright** action. The in-game
Restart button closes the game, verifies master, installs it, then starts the
clean windowed game again.

## Shared Android build alerts

Install **ntfy** from Google Play on Isabelle's phone, then subscribe to this
same shared topic (the topic field contains only the final part):

`bloodright-build-c9a4e71f0db843c6a2e9`

Allow notifications. Every successful Bloodright Push sends a “build ready”
alert to both subscribed phones.

## First playable encounter

The First Vault contains a large red `D` Fire Dragon in the upper-right. When
the player moves within ten tiles, navigation locks and D&D-style combat starts.
The player must fire a broken arrow; the log shows both dice rolls before the
dragon’s fireball and the Long Night death scene.

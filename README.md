[![Distro](https://github.com/outrightmental/GameLauncher/actions/workflows/distro.yml/badge.svg)](https://github.com/outrightmental/GameLauncher/actions/workflows/distro.yml)
<a href="https://godotengine.org/">![Godot](https://img.shields.io/badge/Godot-4.4.1%2B-478cbf)</a>
<a href="https://discord.com/channels/720514857094348840/740983213756907561">![Discord](https://img.shields.io/badge/Comms-Discord-5865f2)</a>

# Game Launcher

Game Launcher for the [Noisebridge 1v1 Coffee Table](https://www.noisebridge.net/wiki/Coffee_Table)

## Operation

Requires Windows 10 or later.

On your computer, create a folder that will be used as the root of the game library resources. Let's call this folder the **Game Library Folder**.

The default location of the **Game Library Folder** is `C:\Users\<username>\Documents\GameLibrary`.

Download the [latest release](releases/latest) and save **GameLauncher.exe** in the **Game Library Folder**.

If you want the Game Launcher to start automatically when you log in to your computer, you can add **GameLauncher.exe** to your startup applications.

### Game Library Manifest JSON file

You'll need to create a **games.json** file in the **Game Library Folder**. This file contains the list of games that will be displayed in the Game Launcher.

Use the example [games.json](example/games.json) as a template.

By default, the Game Launcher will look for the **games.json** file in the same directory as **GameLauncher.exe**.

You can also place a **games.json** file in the default user home location, which is `C:\Users\<username>\Documents\GameLibrary\games.json`.

#### Installing from a private repository

If you want to install games from a private repository, you'll need to provide a GitHub Personal Access Token (PAT) with read access to the following scopes:

- **Metadata**
- **Actions**
- **Contents**

You can create a PAT by following the instructions [here](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token).

Once you have created the PAT, you will include it in your [Game Library Manifest JSON file](#game-library-manifest-json-file) in the `repo_token` field.

#### Installing a specific artifact

You can specify a specific artifact to download from the artifacts available in the latest release by using the `repo_artifact_filter` field in the [Game Library Manifest JSON file](#game-library-manifest-json-file).

This value will be used as a case-insensitive substring filter against the artifact names in the latest release.

## Continuous Integration

Leverages the GitHub marketplace action [godot-ci](https://github.com/marketplace/actions/godot-ci)

When a tag is pushed to the repository, [this workflow](.github/workflows/distro.yml) will automatically build the release artifacts and attach them to the tag.

To build & publish a release:
1. [Create a tag](https://git-scm.com/book/en/v2/Git-Basics-Tagging) at the commit you want to release. The tag should be the version name you want to give the release, e.g. `v2.1`
2. [Create a release](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository) based on the tag

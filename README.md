[![Distro](https://github.com/outrightmental/GameLauncher/actions/workflows/distro.yml/badge.svg)](https://github.com/outrightmental/GameLauncher/actions/workflows/distro.yml)
<a href="https://godotengine.org/">![Godot](https://img.shields.io/badge/Godot-4.4.1%2B-478cbf)</a>
<a href="https://discord.com/channels/720514857094348840/740983213756907561">![Discord](https://img.shields.io/badge/Comms-Discord-5865f2)</a>

# Game Launcher

Game Launcher for the [Noisebridge 1v1 Coffee Table](https://www.noisebridge.net/wiki/Coffee_Table)

## Requirements

Windows 10 or later.

## Operation

On your computer, create a folder that will be used as the root of the game library resources. Let's call this folder the **Game Library Folder**.

Download the [latest release](releases/latest) and save **GameLauncher.exe** in the **Game Library Folder**.

For example, if your username is `noise` you might create a folder at `C:\Users\noise\Documents\GameLibrary`.

If you want the Game Launcher to start automatically when you log in to your computer, you can add **GameLauncher.exe** to your startup applications.

## games.json

You'll need to create a **games.json** file in the **Game Library Folder**. This file contains the list of games that will be displayed in the Game Launcher.

Use the example [games.json](example/games.json) as a template.


## Continuous Integration

Leverages the GitHub marketplace action [godot-ci](https://github.com/marketplace/actions/godot-ci)

When a tag is pushed to the repository, [this workflow](.github/workflows/distro.yml) will automatically build the release artifacts and attach them to the tag.

To build & publish a release:
1. [Create a tag](https://git-scm.com/book/en/v2/Git-Basics-Tagging) at the commit you want to release. The tag should be the version name you want to give the release, e.g. `v2.1`
2. [Create a release](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository) based on the tag

@echo off
title RE-RUN - Direct Launch: Secret Alternate Realm (The Shadow District)
cd /d "%~dp0"
echo ===================================================
echo      RE-RUN: SECRET ALTERNATE REALM (DIRECT ACCESS)
echo   Theme: The Shadow District / Apocalypse Protocol
echo   Monsters: Zombies, Skeletons, Aerial Witches
echo   Objective: Reach the Dimensional Extraction Rift!
echo ===================================================
echo Controls:
echo   [A] / [D] or [Left] / [Right] : Move & Dodge
echo   [Space] / [W] / [Up]          : Jump & Double Jump
echo   [J] / [Z] / Left-Click        : Energy Slash Monsters!
echo ===================================================
start "" "godot_bin\Godot_v4.3-stable_win64_console.exe" --path "RE-RUN\RE-RUN" res://Scenes/Levels/alternate_realm.tscn

@echo off
title RE-RUN - Direct Launch: Level 4 (Desert Biome Dunes)
cd /d "%~dp0"
echo ===================================================
echo             RE-RUN: DIRECT LEVEL 4 LAUNCH
echo   Theme: Desert Biome Dunes
echo   Desc:  Windswept Sandy Expanse
echo   Speed: 280 px/s
echo ===================================================
echo Controls:
echo   [A] / [D] or [Left] / [Right] : Move & Dodge
echo   [Space] / [W] / [Up]          : Jump & Double Jump
echo   [S] / [Down]                  : Slide under pipes
echo   [J] / [Z] / Left-Click        : Energy Slash
echo ===================================================
set COLLEGE_RUN_LEVEL=4
start "" "godot_bin\Godot_v4.3-stable_win64_console.exe" --path "RE-RUN\RE-RUN" res://Scenes/Levels/level_1.tscn -- --level 4

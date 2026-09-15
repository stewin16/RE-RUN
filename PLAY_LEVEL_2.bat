@echo off
title RE-RUN - Direct Launch: Level 2 (Megacity Landscape)
cd /d "%~dp0"
echo ===================================================
echo             RE-RUN: DIRECT LEVEL 2 LAUNCH
echo   Theme: Megacity Landscape
echo   Desc:  Futuristic Downtown Skyscrapers
echo   Speed: 240 px/s
echo ===================================================
echo Controls:
echo   [A] / [D] or [Left] / [Right] : Move & Dodge
echo   [Space] / [W] / [Up]          : Jump & Double Jump
echo   [S] / [Down]                  : Slide under pipes
echo   [J] / [Z] / Left-Click        : Energy Slash
echo ===================================================
set COLLEGE_RUN_LEVEL=2
start "" "godot_bin\Godot_v4.3-stable_win64_console.exe" --path "RE-RUN\RE-RUN" res://Scenes/Levels/level_1.tscn -- --level 2

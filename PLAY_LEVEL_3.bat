@echo off
title RE-RUN - Direct Launch: Level 3 (Beach & Coastal Route)
cd /d "%~dp0"
echo ===================================================
echo             RE-RUN: DIRECT LEVEL 3 LAUNCH
echo   Theme: Beach & Coastal Route
echo   Desc:  Sunny Seaside Highway
echo   Speed: 260 px/s
echo ===================================================
echo Controls:
echo   [A] / [D] or [Left] / [Right] : Move & Dodge
echo   [Space] / [W] / [Up]          : Jump & Double Jump
echo   [S] / [Down]                  : Slide under pipes
echo   [J] / [Z] / Left-Click        : Energy Slash
echo ===================================================
set COLLEGE_RUN_LEVEL=3
start "" "godot_bin\Godot_v4.3-stable_win64_console.exe" --path "RE-RUN\RE-RUN" res://Scenes/Levels/level_1.tscn -- --level 3

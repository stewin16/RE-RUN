@echo off
title RE-RUN - Direct Launch: Level 6 (Foozle Desert Canyon)
cd /d "%~dp0"
echo ===================================================
echo             RE-RUN: DIRECT LEVEL 6 LAUNCH
echo   Theme: Foozle Desert Canyon
echo   Desc:  Rugged Stone Plateaus & Canyons
echo   Speed: 315 px/s
echo ===================================================
echo Controls:
echo   [A] / [D] or [Left] / [Right] : Move & Dodge
echo   [Space] / [W] / [Up]          : Jump & Double Jump
echo   [S] / [Down]                  : Slide under pipes
echo   [J] / [Z] / Left-Click        : Energy Slash
echo ===================================================
set COLLEGE_RUN_LEVEL=6
start "" "godot_bin\Godot_v4.3-stable_win64_console.exe" --path "RE-RUN\RE-RUN" res://Scenes/Levels/level_1.tscn -- --level 6

@echo off
title RE-RUN - Direct Launch: Level 10 (Academy Cyber City Finale)
cd /d "%~dp0"
echo ===================================================
echo             RE-RUN: DIRECT LEVEL 10 LAUNCH
echo   Theme: Academy Cyber City Finale
echo   Desc:  Climax Examination Sprint
echo   Speed: 365 px/s
echo ===================================================
echo Controls:
echo   [A] / [D] or [Left] / [Right] : Move & Dodge
echo   [Space] / [W] / [Up]          : Jump & Double Jump
echo   [S] / [Down]                  : Slide under pipes
echo   [J] / [Z] / Left-Click        : Energy Slash
echo ===================================================
set COLLEGE_RUN_LEVEL=10
start "" "godot_bin\Godot_v4.3-stable_win64_console.exe" --path "RE-RUN\RE-RUN" res://Scenes/Levels/level_1.tscn -- --level 10

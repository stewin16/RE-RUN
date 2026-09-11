@echo off
title RE-RUN - The Campus Runner
cd /d "%~dp0"
echo ===================================================
echo             STARTING RE-RUN (GODOT 2D)
echo ===================================================
echo Controls:
echo   [A] / [D] or [Left] / [Right] : Run & Move
echo   [Space] / [W] / [Up]          : Jump & Double Jump
echo   [S] / [Down]                  : Slide under pipes
echo   [J] / [F] / [Z] / Left-Click  : Slash / Action
echo   [P]                           : Pause
echo   [R]                           : Quick Restart
echo ===================================================
start "" "godot_bin\Godot_v4.3-stable_win64_console.exe" --path "RE-RUN\RE-RUN"

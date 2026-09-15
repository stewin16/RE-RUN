@echo off
title RE-RUN - Level Selection Launcher
:menu
cls
echo ========================================================
echo               RE-RUN: LEVEL SELECTION LAUNCHER
echo ========================================================
echo   [1]  Level 1  - Academy Cyber City (Original)
echo   [2]  Level 2  - Megacity Landscape (Skyscrapers)
echo   [3]  Level 3  - Beach & Coastal Route (Seaside)
echo   [4]  Level 4  - Desert Biome Dunes (Sands)
echo   [5]  Level 5  - Volcano & Lava Peaks (Secret Realm!)
echo   [6]  Level 6  - Foozle Desert Canyon (Plateaus)
echo   [7]  Level 7  - Underground Caverns (Crystals)
echo   [8]  Level 8  - Volcano Highlands (Ember Forest)
echo   [9]  Level 9  - Metropolitan Skyline (Rooftops)
echo   [10] Level 10 - Academy Cyber City Finale
echo   --------------------------------------------------------
echo   [S]  Secret   - The Shadow District (Alternate Realm)
echo   [M]  Main     - Full Game (Main Menu & Intro)
echo   [Q]  Quit
echo ========================================================
set /p choice="Select Level [1-10, S, M, Q]: "

if /i "%choice%"=="1"  (call PLAY_LEVEL_1.bat & goto end)
if /i "%choice%"=="2"  (call PLAY_LEVEL_2.bat & goto end)
if /i "%choice%"=="3"  (call PLAY_LEVEL_3.bat & goto end)
if /i "%choice%"=="4"  (call PLAY_LEVEL_4.bat & goto end)
if /i "%choice%"=="5"  (call PLAY_LEVEL_5.bat & goto end)
if /i "%choice%"=="6"  (call PLAY_LEVEL_6.bat & goto end)
if /i "%choice%"=="7"  (call PLAY_LEVEL_7.bat & goto end)
if /i "%choice%"=="8"  (call PLAY_LEVEL_8.bat & goto end)
if /i "%choice%"=="9"  (call PLAY_LEVEL_9.bat & goto end)
if /i "%choice%"=="10" (call PLAY_LEVEL_10.bat & goto end)
if /i "%choice%"=="s"  (call PLAY_SECRET_ALTERNATE_REALM.bat & goto end)
if /i "%choice%"=="m"  (call PLAY_GAME.bat & goto end)
if /i "%choice%"=="q"  (exit)

echo Invalid choice, try again.
pause
goto menu

:end
exit

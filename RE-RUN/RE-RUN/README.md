# RE-RUN

RE-RUN is a pixel-art college runner built with Godot 4.3. Run through a procedurally continuing campus track, collect coins and knowledge, avoid hazards, answer technical quiz terminals, and defeat the final-exam boss.

## Requirements

- Godot 4.3 or newer
- Windows, Linux, or macOS
- A display that can run the 480 x 270 pixel viewport

## Run The Game

1. Open this folder in Godot.
2. Press **Play Project**.
3. The main scene is `Scenes/UI/main_menu.tscn`.

From the parent `CollegeRun` folder on Windows, `PLAY_GAME.bat` launches this project automatically.

## Controls

| Action | Keys |
| --- | --- |
| Move / run | A, D, Left Arrow, Right Arrow |
| Jump / double jump | Space, W, Up Arrow |
| Slide | S, Down Arrow |
| Slash / action | J, F, Z, or Left Click |
| Pause | P or Escape |
| Quick restart | R while paused or after game over |

## Gameplay

- Collect coins to increase the score.
- Collect knowledge and memory pickups for educational facts and quiz advantages.
- Use hints and lifelines during technical quiz encounters.
- Avoid spikes, pipes, barriers, enemies, and exam attacks.
- Reach the final exam and answer enough questions correctly to pass.
- Choose a runner from the college roster before starting a run.

## Project Layout

- `Scenes/UI`: main menu and in-game HUD
- `Scenes/Levels`: playable level scenes
- `Scenes/Objects`: hazards, enemies, pickups, terminals, and boss objects
- `Scenes/Player`: player scene
- `Scripts/UI`: menu, HUD, and settings logic
- `Scripts/Objects`: gameplay object behavior
- `Assets`: pixel art, audio, fonts, and imported resources

## Text Layout Notes

The game uses a fixed 480 x 270 pixel viewport with integer canvas scaling. Long quiz questions, facts, runner descriptions, and modal headings wrap inside their panels, while compact HUD counters are clipped to their available space so text does not escape its container.

## Development

Use the Godot editor to edit scenes and scripts. Do not commit the `.godot/` directory; it is local editor/import cache and is ignored by `.gitignore`.

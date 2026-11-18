# NITISH 5

An original mobile-first 3D open-world city action/driving prototype built with Godot 4.

## Implemented gameplay
- Procedural low-poly city blocks with collision
- Asphalt road grid and road markings
- Third-person character movement, sprint and jump
- Drivable starter car with acceleration, reverse, steering and brake
- Enter/exit vehicle interaction
- Ambient traffic vehicles moving through the city
- Pedestrian NPCs with simple roaming AI
- Toggleable police pursuit prototype
- Five collectible mission checkpoints
- Local mission progress save
- Touchscreen buttons plus keyboard controls
- Android debug APK GitHub Actions workflow

## Run locally
1. Install Godot 4.3.
2. Import `project.godot`.
3. Press F5 to run the main scene.

## Controls
- WASD / arrow keys: move
- Space: jump
- Shift: sprint
- E: enter or exit the nearby car
- F: toggle police pursuit
- B: brake
- Mobile: on-screen movement, jump, brake, enter/exit and wanted buttons

## Android APK
Every push to `main` and manual workflow dispatch triggers an Android debug APK build.
Open the **Actions** tab, select **Build NITISH 5 Android APK**, and download the artifact named `NITISH-5-Android-APK`.

The APK is debug-signed for testing. A public Play Store release requires a private release keystore and secure GitHub Actions secrets. Do not commit signing keys or passwords.

## Project structure
- `main.tscn`: main game scene
- `scripts/game.gd`: world generation, missions, UI and gameplay orchestration
- `scripts/player.gd`: third-person player controller
- `scripts/car.gd`: drivable vehicle controller
- `scripts/traffic_vehicle.gd`: ambient traffic movement
- `scripts/pedestrian_ai.gd`: roaming pedestrian AI
- `scripts/police_ai.gd`: simple pursuit prototype
- `.github/workflows/android-apk.yml`: Android build pipeline

## Roadmap
- Character and NPC animation rigs
- Better vehicle physics, wheels and multiple vehicles
- Weapon system, combat and health
- More missions, interiors, minimap and save slots
- Improved city assets, audio and device-specific optimization

This is an original prototype. It is not affiliated with, endorsed by, or a copy of Grand Theft Auto or Rockstar Games.

# Ashes of the Meadow — Design Document

**Tagline:** A lonely sheep drifts through the ruins of space, carried forward by music.

## Concept
A space sheep, a melomaniac, awakens alone in silent outer space. Its world is gone. It discovers a cassette player fused with a bass instrument — sound becomes its only way to move through zero gravity. Its goal: survive, gather materials, build a small vessel, find other lost sheep, and create a new home for the flock.

## Tone
Nostalgic, soft, lonely, tender, sad but hopeful. Cosmic silence broken by music. Rebuilding after loss.

## Controls
| Key | Action |
|-----|--------|
| A / D or Arrow Keys | Aim / Rotate |
| Space | Bass pulse (tap for quick, hold for charged) |
| E | Interact / Collect |
| Tab | Open build panel (future) |

## Demo Flow (5-7 minutes)
1. **Awakening** — Black screen fades in. Sheep floats in silence. Narration text appears.
2. **Discovery** — A warm glow nearby. Sheep drifts toward the cassette-bass device.
3. **Tutorial** — Player learns: Space = pulse/move, A/D = aim, E = interact.
4. **Exploration** — Navigate a small field of floating debris, ruins, and collectibles.
5. **Gathering** — Collect salvage (x3), wool fiber (x2), tape fragments (x2), stardust (x1).
6. **Building** — Return to the home-frame. Build hull (3 salvage + 2 wool), then antenna (2 tape + 1 stardust).
7. **Ending** — Antenna picks up a faint signal. A distant bleat. "You are not alone."

## Collectibles
| Item | Count | Used For |
|------|-------|----------|
| Salvage | 3 | Hull |
| Wool Fiber | 2 | Hull |
| Tape Fragment | 2 | Antenna |
| Stardust | 1 | Antenna |

## Build Recipes
- **Hull**: 3 Salvage + 2 Wool Fiber → structural shell
- **Antenna**: 2 Tape Fragments + 1 Stardust → signal receiver

## Art Direction
- Painterly, soft, storybook-like
- Warm colors against deep dark space
- All sprites procedurally generated (no external assets needed)
- Charming pixel-art sheep with fluffy wool body and dark face

## Audio Direction
- Procedurally generated bass notes (sine waves with harmonics)
- Expanding sound rings as visual feedback
- Silence is meaningful — ambient is nearly absent
- Future: cassette hiss, tape warble, sparse melodic motifs

## Technical Stack
- **Engine**: Godot 4.x (GL Compatibility renderer)
- **Language**: GDScript
- **Target**: Web export (itch.io), then Steam
- **Resolution**: 1280x720, stretch mode: canvas_items
- **Assets**: 100% procedural (zero imported images/audio files)

## Architecture
```
project.godot
scripts/
  autoload/game_state.gd    — singleton: phase, inventory, build progress
  player/sheep.gd            — CharacterBody2D: rotation, charging, pulsing
  player/sound_ring.gd       — expanding visual rings on pulse
  objects/collectible.gd     — Area2D: bobbing items with interact()
  objects/debris.gd          — StaticBody2D: floating obstacles
  objects/home_base.gd       — build station with prompts
  objects/cassette_pickup.gd — initial device pickup trigger
  world/demo_world.gd        — phase sequencing, narration, ending
  world/procedural_sprites.gd — generates all textures at runtime
  world/sprite_loader.gd     — assigns textures on scene load
  ui/hud.gd                  — inventory display + hints
assets/
  shaders/starfield.gdshader — parallax star background
scenes/
  main.tscn                  — complete demo scene (all inline)
```

## Browser Optimization Notes
- GL Compatibility renderer (WebGL 2)
- No imported textures — all procedural (tiny download)
- No audio files — all generated via AudioStreamGenerator
- Compact play area (~1000x500 px world)
- No heavy physics — simple CharacterBody2D with manual velocity
- No particle textures — GPUParticles2D with defaults
- Target: < 5MB web export

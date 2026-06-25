# Vegan Guys

Ein 3D-Multiplayer-Partyspiel im Stil von Fall Guys — mit veganem Theme. Bis zu 6 Spieler kämpfen in Minigames um den letzten Platz. Wer zuletzt überlebt, gewinnt.

## Anforderungen

- **Godot 4.6** oder **4.7** ([Download](https://godotengine.org/download))
- Für Steam später: [GodotSteam](https://github.com/GodotSteam/GodotSteam) Plugin
- Für eigene Modelle: **Blender** (GLB/GLTF Export)

## Projekt öffnen

1. Godot 4.6+ starten
2. **Import** → Ordner `vegan-guys` auswählen
3. `project.godot` öffnen
4. **F5** drücken zum Starten

## Steuerung

| Taste | Aktion |
|-------|--------|
| WASD | Bewegen |
| Maus | Kamera drehen |
| Leertaste | Springen |
| Shift | Slide |
| Strg (in der Luft) | Dodge / Hechtsprung |
| Linke Maustaste | Waffe benutzen |
| Q / F | Waffe wechseln |
| E (spammen) | Aus Tofu befreien |

## Multiplayer testen (LAN)

1. **Spieler 1:** „Spiel hosten" → „Spiel starten"
2. **Spieler 2–6:** IP des Hosts eingeben (lokal: `127.0.0.1`) → „Spiel beitreten"
3. Host startet das Minigame für alle

> Aktuell: ENet (LAN/Online). Steam-Integration ist vorbereitet und kann über GodotSteam ergänzt werden.

## Szenen

| Szene | Pfad |
|-------|------|
| Hauptmenü | `scenes/main_menu/main_menu.tscn` |
| Survival Cage Minigame | `scenes/minigames/survival_cage/survival_cage.tscn` |
| Spieler | `scenes/player/player.tscn` |

## Minigame: Survival Cage

- 6 Spieler spawnen in einem Käfig aus **einzelnen Tiles**
- Bodenfliesen brechen nach und nach weg (alle ~3 Sekunden)
- Waffen können Knockback, Fallen und Tile-Zerstörung auslösen
- **Unendlich HP** — man stirbt nur durch Fallen oder Tofu-Erstickung
- Letzter Überlebender gewinnt

## Waffen (13 Stück)

| Waffe | Effekt |
|-------|--------|
| Tofukanone | Tofublöcke alle 2s; Treffer = E spammen oder sterben |
| Brokkoli Hammer | Starker Knockback im Nahbereich |
| Smoothie Blaster | Verdeckt Sicht |
| Bananenschalen Werfer | Ausrutschen auf Schalen |
| Salatschleuder | Rotierende Blätter mit Knockback |
| Tomatenbomber | Explosion schleudert hoch |
| Maiskolbenminigun | 3s Dauerfeuer, 4s Cooldown |
| Kokosnuss Mörser | Hohe Flugbahn, Flächenschaden, 20% Tile-Zerstörung |
| Vegane Sahnekanone | −50% Speed für 3s |
| Pilzsprungmine | Versteckte Mine, schleudert hoch |
| Spaghetti Lasso | Zieht Gegner ran (lange Reichweite) |
| Chili Werfer | +200% Speed, +50% Sprunghöhe für 5s |
| Lauchlanze | Extrem lange Nahkampf-Reichweite |

## Assets austauschen (in Godot)

### Spielermodell (Blender)

1. In Blender: Modell + Rig + Animationen erstellen
2. Export als **glTF 2.0 (.glb)**
3. In Godot: `.glb` nach `assets/models/` ziehen
4. `scenes/player/player.tscn` öffnen
5. Unter `Visuals/BodyMesh` das Placeholder-Mesh durch dein importiertes Modell ersetzen
6. Optional: `AnimationPlayer` vom GLB an `Visuals` anhängen

### Waffen-Modelle

Jede Waffe ist eine eigene Szene unter `scenes/weapons/`. Einfach das `Mesh`-Kind durch dein Modell ersetzen — die Logik bleibt im Script.

### Tile-Texturen

1. `scenes/minigames/survival_cage/breakable_tile.tscn` öffnen
2. Am `MeshInstance3D` neues Material zuweisen oder Textur auf `assets/materials/tile_placeholder.tres` ändern

### Arena-Größe

In `survival_cage.tscn` → Node `Arena` im Inspector:
- `grid_width`, `grid_depth` — Käfiggröße
- `random_break_interval` — wie oft Tiles brechen
- `tiles_per_break_wave` — wie viele pro Welle

## Projektstruktur

```
vegan-guys/
├── project.godot
├── scenes/
│   ├── main_menu/
│   ├── minigames/survival_cage/
│   ├── player/
│   └── weapons/
├── scripts/
│   ├── autoload/        # GameManager, NetworkManager
│   ├── player/
│   ├── weapons/
│   ├── minigame/
│   └── ui/
└── assets/
    ├── models/          # Hier Blender-Modelle ablegen
    ├── materials/
    └── textures/
```

## Steam-Veröffentlichung (nächste Schritte)

1. [GodotSteam](https://github.com/GodotSteam/GodotSteam) als Addon installieren
2. `NetworkManager` auf Steam P2P/Networking umstellen
3. Steam App ID in Godot Export Presets setzen
4. Export Template für Windows/Linux erstellen

## Nächste geplante Features

- Weitere Minigames
- Lobby mit Waffenwahl
- Cosmetics / Skins
- Sound & Musik
- Dedicated Server

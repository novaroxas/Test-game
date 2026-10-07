# Hand Clash

A small Roblox rock-paper-scissors game with a landscaped lounge, a neon arena,
smooth character reactions, 3D choice reveals, and a responsive interface.
Play against ROBO on your own, or queue for a duel against another player in
the same server.

## Play in Roblox Studio

1. On [GitHub](https://github.com/novaroxas/Test-game), click **Code → Download ZIP**.
   Extract the ZIP in File Explorer, then find `build/HandClash.rbxlx` inside
   the extracted folder. The place file is included; no build tools are needed
   to play it.
2. Open the file in **Roblox Studio** using **File → Open from File**.
3. Press Studio's **Play** button and select **Practice with ROBO** in the game
   menu. You can reopen the menu with the small **Play** button in the corner.
4. Click or tap **Rock**, **Paper**, or **Scissors**. On desktop, you can also
   press **1**, **2**, or **3**.
5. To test multiplayer, use Studio's **Test** tab to start a local server with
   **2 clients**. Select **Find a match** in both client windows.

The lounge has benches you can sit on, planters, warm lamps, a central sculpture,
and two play kiosks. Close the menu to explore. Walk to a kiosk and use its
prompt (press **E** on desktop or tap on mobile) to practice or queue. While
waiting for another player, you can keep walking around or sitting in the
lounge; a compact queue panel lets you cancel at any time. Matches start
automatically when an opponent joins.

The arena and interface are created automatically when the game starts. No
asset uploads, plugins, API keys, external services, or paid assets are needed.
Use Studio's normal **Publish to Roblox** flow when you want to release it.

## How it works

- First to **3 points** wins: best of five decisive rounds; ties replay.
- Players have **7 seconds** to choose. The reveal happens once both are ready,
  or when the timer runs out.
- Choices are locked and remain private until the reveal. The server determines
  the outcome; clients cannot choose their score or the opponent's move.
- Missing a choice forfeits that round. If both players time out, it is a tie.
  Three consecutive rounds with no choices end the match as a draw.
- Leaving, resetting your character, or disconnecting forfeits the match.
- ROBO chooses independently before receiving your choice.
- Completed matches return you to the lobby automatically.
- Reveals use three synchronized hand beats before the choice props, scores,
  and result appear. Motion runs locally at render frequency, with eased props,
  gentle idle movement, winner reactions, and fading camera transitions.
- Matchmaking is local to the current server. Scores reset for each match.

## Edit the game

| File | Purpose |
| --- | --- |
| `src/shared/Config.lua` | Title, points required, timer lengths, and bot name |
| `src/shared/Rules.lua` | Choice validation and win rules |
| `src/shared/Presentation.lua` | Smooth local character and reveal animation |
| `src/server/Game.server.lua` | Matchmaking, private choices, timers, cleanup |
| `src/server/Arena.lua` | Lobby, arena, ROBO, props, and character animations |
| `src/client/Interface.client.lua` | UI, camera, keyboard input, and confetti |

Change source files and run `python3 tools/build_place.py` again to update the
place file. Reopening a rebuilt file replaces local Studio edits, so save any
Studio-only work separately first. The generated place file is included in Git
for easy downloading; rebuild and commit it after source changes to keep it
up to date. The source is the editable version.

The project also includes `default.project.json` for **Rojo** users:

```sh
rojo build default.project.json -o build/HandClash.rbxlx
rojo serve default.project.json
```

Connect the Rojo Studio plugin to sync source changes. Rojo is optional; the
included Python builder needs only Python 3.9 or later and its standard library.

## Validation

Automated checks cover all nine choice combinations, malformed choices,
timeouts, ties, scoring, private choices, locked choices, stale submissions,
rate limiting, queue cancellation, practice mode, disconnects, resets, and
match cleanup. The server tests execute the actual server script with mocked
Roblox services and a deterministic clock.

Run from the repository root using a Lua 5.3-compatible interpreter:

```sh
lua tests/rules.spec.lua
lua tests/server.spec.lua
lua tests/presentation.spec.lua
python3 -m unittest discover -s tests -p 'test_*.py'
```

These Lua files also run with `fengari-node-cli`. All game scripts use syntax
compatible with both Lua 5.3 and Roblox Luau. Production runs inside Roblox;
no Lua interpreter or Node.js is required by the game itself.

Roblox Studio is not available in this cloud workspace. Actual engine execution,
avatar animations, camera framing, touch layout, and multiplayer replication
still need the Studio checks below; the automated tests do not verify those.

### Studio checks

- Play solo: explore the lounge, sit on a bench, then start practice at a kiosk.
  Complete a match, watch the reveal props and character
  reactions, and confirm the camera and movement return to normal in the lobby.
- Start two clients: queue both, verify the cyan player appears on the left and
  pink player on the right, and play a complete match.
- Queue just one client first: walk and sit in the lounge while waiting, cancel
  the queue, then requeue. Reset while queued and verify the queue panel clears.
- Select a choice in one client first: the other client should only see a
  readiness message, never the selected choice before the reveal.
- Leave a round without choosing and check the timeout result. Stop one client
  or reset a character mid-match and check that the remaining player wins.
- Use Studio's device emulator to check a phone in landscape and portrait.
- Test both R6 and R15 avatar settings, particularly arm reactions and stage
  placement. Animation uses tweens and does not require published animations.

This is a compact starter game: it has no persistent wins, shop, cross-server
matchmaking, monetization, or audio.

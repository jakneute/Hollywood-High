# Hollywood High

A modern take on old Windows 95 edutainment software.

## Features

- **Dynamic Screenplay Editor:** Create and edit complex scripts with support for Dialogue, Action, and Scene blocks.
- **Advanced TTS Integration:** Powered by the TiSpeech engine, providing unique voices for a diverse cast of characters.
- **Interactive Theater Mode:** Watch your screenplays come to life with automated character positioning, movement, and voice-over.
- **Staging & Splice Modes:** Fine-tune character placement and easily insert script blocks anywhere in the timeline.
- **Rich Asset Library:** Includes a wide variety of high-quality backgrounds and character sprites for diverse storytelling.

## Project Structure

- `objects/`: Core game logic and UI components (e.g., `oHollywoodUI`).
- `scripts/`: Helper functions and engine logic (e.g., TTS bridge, sequencer).
- `datafiles/`: External assets and tools, including the `talkit` bridge and asset libraries.
- `rooms/`: Main application environments.

## Development

This project is built using GameMaker 2024.14+. It utilizes a custom C# bridge for advanced TTS functionality.

### Requirements

- GameMaker (2024.14.4.222 or newer)
- Windows (for TTS bridge compatibility)

## License

All rights reserved. (C) 2026

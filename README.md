# TTS Server

Local text-to-speech server using Qwen3-TTS. Optimized for Apple Silicon Macs.

## One-Command Install

```bash
curl -fsSL https://raw.githubusercontent.com/larrywcl/tts-server/main/install.sh | bash
```

This will:
- Install Python 3.12 (via Homebrew)
- Set up a virtual environment at `~/.tts-server/`
- Install qwen-tts and dependencies
- Download the TTS model (~3GB)
- Create a start script

## Usage

**Start the server:**
```bash
~/.tts-server/start.sh --port 11435
```

**Run as background service (auto-start on boot):**
```bash
cp ~/.tts-server/com.westcreeklabs.tts-server.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.westcreeklabs.tts-server.plist
```

## API

### Health Check
```bash
curl http://localhost:11435/health
```

### Generate Speech
```bash
curl -X POST http://localhost:11435/generate \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello world!", "speaker": "Ryan"}' \
  -o output.wav
```

### Generate Batch (Multiple Segments)
```bash
curl -X POST http://localhost:11435/generate_batch \
  -H "Content-Type: application/json" \
  -d '{
    "segments": [
      {"text": "Welcome to the show!", "speaker": "Ryan"},
      {"text": "Thanks for having me.", "speaker": "Aiden"}
    ],
    "pause_seconds": 0.5
  }' \
  -o podcast.wav
```

### List Speakers
```bash
curl http://localhost:11435/speakers
```

## Available Speakers

| Speaker | Voice | Best For |
|---------|-------|----------|
| Ryan | Dynamic male | Main host |
| Aiden | Sunny American male | Co-host |
| Vivian | Bright young female | Energetic |
| Serena | Warm gentle female | Calm |
| Dylan | Beijing male | Chinese |
| Eric | Sichuan male | Chinese dialect |

## Parameters

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `text` | string | required | Text to speak |
| `speaker` | string | "Ryan" | Voice to use |
| `language` | string | "English" | Language |
| `instruct` | string | "" | Style instruction (e.g., "Speak with enthusiasm") |

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/larrywcl/tts-server/main/uninstall.sh | bash
```

This removes:
- `~/.tts-server/` directory
- Launch agent (if installed)
- Cached model files
- Temp files

## Requirements

- macOS (Apple Silicon recommended)
- ~5GB disk space
- ~4GB RAM available

## License

MIT

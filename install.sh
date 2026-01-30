#!/bin/bash
# One-command TTS server setup for Mac Mini
# Usage: curl -fsSL https://raw.githubusercontent.com/larrywcl/tts-server/main/install.sh | bash

set -e

TTS_DIR="$HOME/.tts-server"
REPO_URL="https://github.com/larrywcl/tts-server.git"

echo "🎙️  TTS Server Installer"
echo "========================"
echo ""

# Check we're on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ This script is for macOS only"
    exit 1
fi

# Check for Apple Silicon
if [[ "$(uname -m)" != "arm64" ]]; then
    echo "⚠️  Warning: This is optimized for Apple Silicon (M1/M2/M3/M4/M5)"
fi

# Install Homebrew if needed
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install Python 3.12 via Homebrew (more reliable than conda for this)
echo "🐍 Installing Python 3.12..."
brew install python@3.12 || true

# Create install directory
echo "📁 Setting up $TTS_DIR..."
rm -rf "$TTS_DIR"
mkdir -p "$TTS_DIR"
cd "$TTS_DIR"

# Download server.py directly (simpler than cloning)
echo "📥 Downloading server files..."
curl -fsSL "https://raw.githubusercontent.com/larrywcl/tts-server/main/server.py" -o server.py
chmod +x server.py

if [[ ! -f server.py ]]; then
    echo "❌ Failed to download server.py"
    exit 1
fi

# Create virtual environment
echo "🔧 Creating Python environment..."
/opt/homebrew/opt/python@3.12/bin/python3.12 -m venv .venv
source .venv/bin/activate

# Install dependencies
echo "📚 Installing dependencies (this takes a few minutes)..."
pip install --upgrade pip
pip install qwen-tts fastapi uvicorn

# Download model
echo "🧠 Downloading TTS model (~3GB)..."
python -c "
from qwen_tts import Qwen3TTSModel
import torch
print('Downloading model...')
model = Qwen3TTSModel.from_pretrained(
    'Qwen/Qwen3-TTS-12Hz-1.7B-CustomVoice',
    device_map='cpu',
    dtype=torch.float32,
)
print('Model cached!')
del model
"

# Create start script
cat > start.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source .venv/bin/activate
python server.py "$@"
EOF
chmod +x start.sh

# Create launchd plist for auto-start (optional)
cat > com.westcreeklabs.tts-server.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.westcreeklabs.tts-server</string>
    <key>ProgramArguments</key>
    <array>
        <string>$TTS_DIR/start.sh</string>
        <string>--port</string>
        <string>11435</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>WorkingDirectory</key>
    <string>$TTS_DIR</string>
    <key>StandardOutPath</key>
    <string>/tmp/tts-server.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/tts-server.err</string>
</dict>
</plist>
EOF

echo ""
echo "✅ Installation complete!"
echo ""
echo "To start the server manually:"
echo "  $TTS_DIR/start.sh --port 11435"
echo ""
echo "To install as a background service (auto-start on boot):"
echo "  cp $TTS_DIR/com.westcreeklabs.tts-server.plist ~/Library/LaunchAgents/"
echo "  launchctl load ~/Library/LaunchAgents/com.westcreeklabs.tts-server.plist"
echo ""
echo "To test:"
echo "  curl http://localhost:11435/health"
echo ""

# YT-Agent: AI-Powered Educational Video Generator

**Create beautiful animated educational videos with just one topic!**

YT-Agent uses AI (Large Language Models) to automatically:
1. Create a lesson plan for your topic
2. Generate voice-over narration (text-to-speech)
3. Write animation code (using Manim, the math animation library)
4. Perfectly sync audio with animations

---

## What Does It Create?

```
You type: "What is Machine Learning?"

YT-Agent creates:
├── A 3-5 minute animated video
├── Professional voice narration
├── Beautiful text animations
└── Perfectly synced audio-visual content
```

---

## Quick Start (5 Minutes Setup)

### Step 1: Get the Code

```bash
# Clone this repository
git clone https://github.com/rajvardhandeshmukh/yt-agent.git

# Go into the folder
cd yt-agent
```

### Step 2: Create a Virtual Environment

**What is this?** A virtual environment keeps this project's packages separate from other Python projects.

**On Windows:**
```bash
# Create virtual environment
python -m venv venv311

# Activate it (you'll see (venv311) at the start of your terminal)
venv311\Scripts\activate
```

**On Mac/Linux:**
```bash
# Create virtual environment
python3 -m venv venv311

# Activate it
source venv311/bin/activate
```

### Step 3: Install Required Packages

```bash
# Install all dependencies
pip install -r requirements.txt
```

This installs:
- `manim` - Creates the animations
- `groq` - Connects to the AI (LLM)
- `edge-tts` - Creates voice narration
- And other helper packages

### Step 4: Get Your Free API Key

You need an API key to use the AI. It's **FREE**!

1. Go to [https://console.groq.com](https://console.groq.com)
2. Sign up with Google or email
3. Click "API Keys" in the left menu
4. Click "Create API Key"
5. Copy the key (it looks like: `gsk_xxxxxxxxxxxxx`)

### Step 5: Set Up Your API Key

Create a file called `.env` in the project folder:

```bash
# Windows (PowerShell)
echo "GROQ_API_KEY=your_api_key_here" > .env

# Mac/Linux
echo "GROQ_API_KEY=your_api_key_here" > .env
```

**Replace `your_api_key_here` with your actual key!**

### Step 6: Install Manim Dependencies

Manim needs some extra software to work:

**Windows:**
1. Install [MiKTeX](https://miktex.org/download) (for LaTeX - math formulas)
2. Install [FFmpeg](https://ffmpeg.org/download.html) (for video processing)
   - Or use: `choco install ffmpeg` if you have Chocolatey

**Mac:**
```bash
brew install mactex ffmpeg
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt install texlive-full ffmpeg
```

---

## How to Use

### 1. Run the Program

```bash
python main.py
```

### 2. Enter Your Topic

The program will ask:
```
Enter video topic: 
```

Type any educational topic, like:
- "What is Machine Learning?"
- "How does the Internet work?"
- "Explain Photosynthesis"
- "Docker for Beginners"

### 3. Choose Voice Engine

```
SELECT TTS ENGINE
[1] Edge TTS (FAST) - Microsoft voices
[2] Chatterbox (HIGH QUALITY) - AI voice
```

**Recommend: Choose 1** (Edge TTS is fast and sounds great!)

### 4. Choose Voice Style

```
Available voices:
[1] en-US-GuyNeural (male, American)
[2] en-US-AriaNeural (female, American)
[3] en-GB-RyanNeural (male, British)
[4] en-IN-NeerjaNeural (female, Indian)
```

### 5. Review the Plan

The AI will show you the lesson plan. You can:
- Type `a` to **approve** and continue
- Type `i` to **improve** (give feedback)
- Type `q` to **quit**

### 6. Wait for Generation

The program will:
1. Generate audio files (30-60 seconds)
2. Generate animation code (10-20 seconds)

### 7. Render Your Video

After generation, you'll see a command like:
```bash
manim -pql --media_dir ./medias -o video_name medias/video_name.py VideoScene
```

**Copy and paste this command to render your video!**

- `-pql` = Preview Quality Low (fast, good for testing)
- Use `-pqh` for High Quality (slower, better looking)

### 8. Watch Your Video!

Your video will be saved in:
```
medias/videos/video_name/480p15/video_name.mp4
```

---

## Project Structure

```
yt-agent/
│
├── main.py              # Start here! Main entry point
├── flow.py              # Connects all the nodes together
├── pocketflow.py        # The workflow engine
├── prompts.py           # All AI prompts live here
│
├── nodes/               # Each step of the pipeline
│   ├── user_input.py    # Gets your topic
│   ├── initial_llm.py   # Creates lesson outline
│   ├── scene_planner.py # Plans each scene
│   ├── voice_over.py    # Generates audio
│   ├── review.py        # Shows you the plan
│   ├── manim_coder.py   # Writes animation code
│   └── output.py        # Shows final result
│
├── utilities/           # Helper functions
│   ├── llm.py          # Talks to the AI
│   ├── tts.py          # Text-to-speech
│   └── parsing.py      # Extracts data from text
│
├── medias/              # All generated files (ignored by git)
│   ├── *.py            # Generated video code
│   ├── audio/          # Voice-over files
│   └── videos/         # Rendered MP4 files
│
├── requirements.txt     # Python packages needed
├── .env                 # Your API key (secret!)
└── .gitignore          # Files to ignore in git
```

---

## How Audio Sync Works

Each visual element gets its **own audio file**:

```
Scene 1:
├── scene_1_title.wav     → "Let's learn about Machine Learning"
├── scene_1_definition.wav → "Machine Learning is..."
├── scene_1_point1.wav    → "First key point..."
├── scene_1_point2.wav    → "Second key point..."
└── scene_1_point3.wav    → "Third key point..."
```

The program **measures** how long each audio file is, then makes the animation wait exactly that long. This creates **perfect sync**!

**Formula:** `wait_time = audio_duration - animation_run_time`

---

## Troubleshooting

### "GROQ_API_KEY not set"
Make sure your `.env` file exists and contains:
```
GROQ_API_KEY=gsk_your_actual_key_here
```

### "LaTeX not found"
Install MiKTeX (Windows) or texlive (Mac/Linux). See Step 6 above.

### "FFmpeg not found"
Install FFmpeg. See Step 6 above.

### "Rate limit exceeded"
Wait 1 minute and try again. The free tier has limits per minute.

### Video renders but audio is missing
Make sure the audio files exist in `medias/audio/` before rendering.

### Text goes off screen
The prompts enforce character limits. If text is still too long, try a shorter topic name.

---

## Configuration

### Change the AI Model

In `utilities/llm.py`, you can change the model:
```python
model="llama-3.1-8b-instant"  # Fast, good quality
# Or use: "llama-3.1-70b-versatile" for better quality (slower)
```

### Change Default Voice

In `nodes/voice_over.py`, change the default voice selection.

### Adjust Character Limits

In `prompts.py`, modify the SCENE_PLANNER_PROMPT limits:
```python
| Title | 30 chars |
| Definition | 55 chars |
| Each Key Point | 35 chars |
```

---

## Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b my-feature`
3. Make your changes
4. Test thoroughly
5. Submit a Pull Request

---

## License

MIT License - Use freely, just give credit!

---

## Author

**Rajvardhan Deshmukh**

GitHub: [@rajvardhandeshmukh](https://github.com/rajvardhandeshmukh)

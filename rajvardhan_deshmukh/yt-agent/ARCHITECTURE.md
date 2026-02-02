# YT-Agent Architecture & Code Documentation

Complete technical documentation with pseudocode explanations and flow diagrams.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Pipeline Architecture](#pipeline-architecture)
3. [Node Explanations](#node-explanations)
4. [Utility Modules](#utility-modules)
5. [Data Flow](#data-flow)
6. [Audio Sync System](#audio-sync-system)

---

## System Overview

YT-Agent is a pipeline-based video generator that converts a topic into an animated educational video.

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  INPUT   │ →  │    AI    │ →  │  AUDIO   │ →  │   CODE   │ →  │  VIDEO   │
│  Topic   │    │ Planner  │    │Generator │    │Generator │    │  Output  │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
     ↓               ↓               ↓               ↓               ↓
  "Docker"     Scene Plan      WAV files       Python code      MP4 file
               for 6 scenes    for each        with Manim       rendered
                               element         animations       video
```

---

## Pipeline Architecture

### Node Connection Diagram

```
START
  │
  ▼
┌─────────────────────────────────────────────────────────────────┐
│                        PHASE 1: PLANNING                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌───────────┐        ┌───────────┐        ┌───────────┐        │
│  │   User    │   →    │  Initial  │   →    │   Scene   │        │
│  │   Input   │        │    LLM    │        │  Planner  │        │
│  └───────────┘        └───────────┘        └───────────┘        │
│       │                     │                    │               │
│   Gets topic          Creates JSON          Expands into        │
│   from user           outline               detailed scenes     │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      PHASE 2: AUDIO GENERATION                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌───────────┐                                                   │
│  │  Voice    │ → Creates 5 audio files per scene:               │
│  │   Over    │   • title.wav                                     │
│  └───────────┘   • definition.wav                                │
│       │          • point1.wav, point2.wav, point3.wav            │
│  Measures                                                         │
│  exact duration                                                   │
│  of each file                                                     │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                       PHASE 3: USER REVIEW                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌───────────┐                                                   │
│  │  Review   │ ← User can:                                       │
│  │   Node    │   [a] Approve → continue                          │
│  └───────────┘   [i] Iterate → regenerate with feedback          │
│       │          [q] Quit    → exit                              │
│       │                                                           │
│       └─── loops back if iterate ────┐                           │
│                                       │                           │
└───────────────────────────────────────┘                           
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                     PHASE 4: CODE GENERATION                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌───────────┐                                                   │
│  │   Manim   │ → Multi-step process:                             │
│  │   Coder   │   1. Generate initial code via AI                 │
│  └───────────┘   2. Validate code via second AI call             │
│       │          3. Apply regex fixes                             │
│       │          4. Inject audio durations for sync              │
│  Outputs .py                                                      │
│  file with                                                        │
│  animations                                                       │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                        PHASE 5: OUTPUT                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌───────────┐                                                   │
│  │  Output   │ → Displays render command                         │
│  │   Node    │   User runs manim to create video                 │
│  └───────────┘                                                   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
                             END
```

---

## Node Explanations

### Node 1: UserInputNode

**Purpose:** Get video topic from user

**Pseudocode:**
```
FUNCTION exec(shared_data):
    1. PROMPT user: "Enter video topic:"
    2. READ user input
    3. STORE input in shared_data["user_query"]
    4. RETURN "next" to trigger InitialLLMNode
END FUNCTION
```

**Data Written:**
| Key | Value | Example |
|-----|-------|---------|
| `user_query` | Topic string | "What is Docker" |

---

### Node 2: InitialLLMNode

**Purpose:** Create structured lesson outline via AI

**Pseudocode:**
```
FUNCTION exec(shared_data):
    1. READ topic from shared_data["user_query"]
    2. SEND to AI: INITIAL_PROMPT + topic
    3. RECEIVE JSON response with:
       - topic name
       - overview text
       - list of scene titles
    4. PARSE JSON from response
    5. STORE result in shared_data["draft_output"]
    6. RETURN "next"
END FUNCTION
```

**Data Flow:**
```
┌─────────────┐                ┌─────────────┐
│ user_query  │ ────────────→  │draft_output │
│ "Docker"    │     AI Call    │  {JSON}     │
└─────────────┘                └─────────────┘
```

**Output Structure:**
```
draft_output = {
    topic: "Docker",
    overview: "Docker is a containerization platform...",
    scenes: [
        {title: "What is Docker?", description: "..."},
        {title: "Benefits", description: "..."},
        ...
    ]
}
```

---

### Node 3: ScenePlannerNode

**Purpose:** Expand outline into detailed scenes with per-element narration

**Pseudocode:**
```
FUNCTION exec(shared_data):
    1. READ draft from shared_data["draft_output"]
    2. SEND to AI: SCENE_PLANNER_PROMPT + draft
    3. RECEIVE detailed scene plan with:
       - Title text (30 chars max)
       - Definition text (55 chars max)
       - 3 Key Points (35 chars each)
       - Audio narration for each element
    4. PARSE narration blocks:
       - Extract TITLE_AUDIO text
       - Extract DEFINITION_AUDIO text
       - Extract POINT1_AUDIO, POINT2_AUDIO, POINT3_AUDIO
    5. STORE in shared_data["scene_plan"] and ["narrations"]
    6. RETURN "next"
END FUNCTION
```

**Output Structure:**
```
narrations = [
    Scene 1:
    ├── scene_id: 1
    ├── title: "Docker is a containerization platform"
    ├── definition: "Docker packages apps with dependencies"
    ├── point1: "Lightweight compared to VMs"
    ├── point2: "Portable across platforms"
    └── point3: "Fast deployment cycles"
    
    Scene 2:
    ├── scene_id: 2
    └── ... (same structure)
]
```

---

### Node 4: VoiceOverNode

**Purpose:** Generate audio files and measure durations for sync

**Pseudocode:**
```
FUNCTION exec(shared_data):
    1. READ narrations from shared_data
    2. CREATE audio folder if not exists
    3. DELETE old audio files (prevent overlap)
    
    4. ASK user: "Choose TTS engine"
       - Option 1: Edge TTS (fast, online)
       - Option 2: Chatterbox (high quality, local)
    
    5. FOR each scene in narrations:
         FOR each element [title, definition, point1, point2, point3]:
           a. GET text for this element
           b. GENERATE audio file: scene_N_element.wav
           c. MEASURE duration of audio file
           d. STORE duration in audio_durations dict
    
    6. STORE audio_durations in shared_data
    7. RETURN "next"
END FUNCTION
```

**Audio Generation Flow:**
```
                     ┌─────────────────────────────┐
                     │     For Each Scene (1-6)    │
                     └──────────────┬──────────────┘
                                    │
            ┌───────────────────────┼───────────────────────┐
            ▼                       ▼                       ▼
    ┌───────────────┐      ┌───────────────┐      ┌───────────────┐
    │ Generate      │      │ Generate      │      │ Generate      │
    │ title.wav     │      │ definition    │      │ point1-3      │
    │               │      │ .wav          │      │ .wav          │
    └───────┬───────┘      └───────┬───────┘      └───────┬───────┘
            │                      │                      │
            ▼                      ▼                      ▼
    ┌───────────────┐      ┌───────────────┐      ┌───────────────┐
    │ Measure       │      │ Measure       │      │ Measure       │
    │ Duration      │      │ Duration      │      │ Duration      │
    │ (2.3 sec)     │      │ (4.5 sec)     │      │ (3.1 sec)     │
    └───────────────┘      └───────────────┘      └───────────────┘
```

**Output Structure:**
```
audio_durations = {
    1: {title: 2.3, definition: 4.5, point1: 3.1, point2: 2.8, point3: 3.4},
    2: {title: 2.1, definition: 5.2, point1: 3.5, ...},
    ...
}
```

---

### Node 5: ReviewNode

**Purpose:** User approval checkpoint with iteration loop

**Pseudocode:**
```
FUNCTION exec(shared_data):
    1. DISPLAY scene plan to user
    2. PROMPT: "[a]pprove / [i]terate / [q]uit"
    3. READ user choice
    
    4. IF choice == "approve":
         RETURN "approved" → go to ManimCoderNode
    
    5. ELSE IF choice == "iterate":
         a. ASK for feedback
         b. SEND to AI: original plan + feedback
         c. RECEIVE improved plan
         d. UPDATE shared_data with new plan
         e. RETURN "iterate" → loop back to ReviewNode
    
    6. ELSE:
         RETURN None → exit pipeline
END FUNCTION
```

**Decision Flow:**
```
                    ┌─────────────────┐
                    │   ReviewNode    │
                    │   Show Plan     │
                    └────────┬────────┘
                             │
                ┌────────────┼────────────┐
                ▼            ▼            ▼
          [a] Approve   [i] Iterate   [q] Quit
                │            │            │
                ▼            ▼            ▼
          ManimCoder    Regenerate      Exit
             Node       with feedback   Pipeline
                             │
                             └──→ Loop back to ReviewNode
```

---

### Node 6: ManimCoderNode

**Purpose:** Generate animation code with perfect audio synchronization

**Pseudocode:**
```
FUNCTION exec(shared_data):
    scene_plan = READ shared_data["scene_plan"]
    audio_durations = READ shared_data["audio_durations"]
    
    ┌──────────────────────────────────────────────────────────┐
    │ STEP 1: Initial Code Generation                          │
    │                                                           │
    │   SEND to AI: MANIM_CODER_PROMPT + scene_plan            │
    │   RECEIVE: Initial Manim Python code                      │
    │   EXTRACT: Python code from markdown blocks               │
    └──────────────────────────────────────────────────────────┘
                              │
                              ▼
    ┌──────────────────────────────────────────────────────────┐
    │ STEP 2: Code Validation                                   │
    │                                                           │
    │   SEND to AI: CODE_VALIDATOR_PROMPT + initial_code       │
    │   RECEIVE: Validated and fixed code                       │
    └──────────────────────────────────────────────────────────┘
                              │
                              ▼
    ┌──────────────────────────────────────────────────────────┐
    │ STEP 3: Regex Cleanup                                     │
    │                                                           │
    │   FIX: Unicode characters → LaTeX commands               │
    │   FIX: Rectangle dimensions for consistent layout         │
    │   FIX: Add scaling to prevent text overflow               │
    │   FIX: Limit to exactly 3 key points                     │
    │   REMOVE: Forbidden elements (Circle, Line, etc.)         │
    └──────────────────────────────────────────────────────────┘
                              │
                              ▼
    ┌──────────────────────────────────────────────────────────┐
    │ STEP 4: Audio Duration Injection (THE MAGIC!)            │
    │                                                           │
    │   FOR each audio reference in code:                       │
    │     1. FIND: add_sound("scene_N_element.wav")            │
    │     2. GET: actual duration from audio_durations          │
    │     3. CALCULATE: wait_time = duration - animation_time   │
    │     4. REPLACE: wait(placeholder) → wait(calculated)      │
    └──────────────────────────────────────────────────────────┘
                              │
                              ▼
    ┌──────────────────────────────────────────────────────────┐
    │ STEP 5: Save Output                                       │
    │                                                           │
    │   CREATE filename: topic_timestamp.py                     │
    │   SAVE code to: medias/filename.py                        │
    │   STORE in shared_data: code, filename, video_name        │
    └──────────────────────────────────────────────────────────┘
    
    RETURN "next"
END FUNCTION
```

---

### Node 7: OutputNode

**Purpose:** Display completion info and render command

**Pseudocode:**
```
FUNCTION exec(shared_data):
    1. READ output_file and video_name from shared_data
    2. DISPLAY: "Video generation complete!"
    3. DISPLAY: "Code saved to: [path]"
    4. DISPLAY: "To render, run:"
    5. DISPLAY: manim command with correct parameters
    6. RETURN None → end pipeline
END FUNCTION
```

---

## Utility Modules

### utilities/llm.py - AI Communication

```
┌─────────────────────────────────────────────────────────────────┐
│                        LLM UTILITY                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  _get_client()                                                   │
│  └─ Creates/returns Groq API client                              │
│  └─ Validates GROQ_API_KEY exists                                │
│                                                                   │
│  call_llm(prompt, input)                                         │
│  └─ Standard AI call                                             │
│  └─ Temperature: 0.2 (slightly creative)                         │
│  └─ Returns: raw text response                                   │
│                                                                   │
│  call_llm_json(prompt, input)                                    │
│  └─ AI call with JSON mode                                       │
│  └─ Temperature: 0 (deterministic)                               │
│  └─ Returns: JSON-formatted response                             │
│                                                                   │
│  call_llm_text(prompt, input)                                    │
│  └─ AI call for free-form text                                   │
│  └─ Temperature: 0.3                                              │
│  └─ Returns: free text response                                  │
│                                                                   │
│  log_llm_output(...)                                             │
│  └─ Logs all AI calls to llm_outputs.txt                        │
│  └─ Includes: timestamp, prompt, input, output                   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### utilities/tts.py - Text-to-Speech

```
┌─────────────────────────────────────────────────────────────────┐
│                        TTS UTILITY                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  get_audio_duration(path)                                        │
│  └─ Returns audio file length in seconds                        │
│  └─ Primary: Uses torchaudio library                            │
│  └─ Fallback: Uses wave module                                   │
│  └─ Default: Returns 20.0 if both fail                          │
│                                                                   │
│  generate_audio_edge(text, path, voice)                          │
│  └─ Uses Microsoft Edge TTS (cloud)                              │
│  └─ Fast, free, requires internet                                │
│  └─ Voice options:                                               │
│      • en-US-GuyNeural (male, American)                          │
│      • en-US-AriaNeural (female, American)                       │
│      • en-GB-RyanNeural (male, British)                          │
│      • en-IN-NeerjaNeural (female, Indian)                       │
│                                                                   │
│  generate_audio(text, path)                                      │
│  └─ Uses Chatterbox TTS (local AI)                               │
│  └─ High quality, requires GPU                                   │
│  └─ Slower than Edge TTS                                         │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### utilities/parsing.py - Text Parsing

```
┌─────────────────────────────────────────────────────────────────┐
│                      PARSING UTILITY                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  extract_json(text)                                              │
│  └─ Finds JSON in text with markdown blocks                     │
│  └─ Handles ```json ... ``` formatting                          │
│  └─ Fixes invalid escapes (like \*)                              │
│  └─ Returns: parsed JSON object                                  │
│                                                                   │
│  extract_code(text)                                              │
│  └─ Finds Python code in markdown blocks                        │
│  └─ Handles ```python ... ``` formatting                        │
│  └─ Returns: clean Python code string                           │
│                                                                   │
│  parse_narrations(text)                                          │
│  └─ Extracts per-element audio texts                            │
│  └─ Looks for: TITLE_AUDIO, DEFINITION_AUDIO, etc.              │
│  └─ Returns: list of scene dicts with audio texts               │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### Shared Data Evolution

```
┌─────────────────────────────────────────────────────────────────┐
│                    SHARED DATA DICTIONARY                        │
└─────────────────────────────────────────────────────────────────┘

After UserInputNode:
┌───────────────────────────────┐
│ user_query: "Docker"          │
└───────────────────────────────┘

After InitialLLMNode:
┌───────────────────────────────┐
│ user_query: "Docker"          │
│ draft_output: {               │
│   topic, overview, scenes[]   │
│ }                             │
└───────────────────────────────┘

After ScenePlannerNode:
┌───────────────────────────────┐
│ user_query: "Docker"          │
│ draft_output: {...}           │
│ scene_plan: "Scene 1:..."     │
│ narrations: [                 │
│   {title, definition, points} │
│ ]                             │
└───────────────────────────────┘

After VoiceOverNode:
┌───────────────────────────────┐
│ ... (all previous)            │
│ audio_durations: {            │
│   1: {title: 2.3, ...}        │
│   2: {title: 2.1, ...}        │
│ }                             │
└───────────────────────────────┘

After ManimCoderNode:
┌───────────────────────────────┐
│ ... (all previous)            │
│ manim_code: "from manim..."   │
│ output_file: "medias/x.py"    │
│ video_name: "docker_123456"   │
└───────────────────────────────┘
```

---

## Audio Sync System

### The Sync Formula

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                   │
│    wait_time = audio_duration - animation_run_time               │
│                                                                   │
│    Example:                                                       │
│    • Audio file: 3.5 seconds                                     │
│    • Animation: 1.0 second                                        │
│    • Wait time: 3.5 - 1.0 = 2.5 seconds                          │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Timeline Visualization

```
TIME ──→   0s         1s         2s         3s         3.5s
           │          │          │          │          │
           │          │          │          │          │
AUDIO      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
           │◀──────────── 3.5 seconds ────────────────▶│
           │                                           │
           │                                           │
ANIMATION  ▓▓▓▓▓▓▓▓▓▓│                                 │
           │◀─ 1.0s ─▶│                                 │
           │          │                                 │
           │          │                                 │
WAIT       │          ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
           │          │◀──────── 2.5 seconds ─────────▶│
           │          │                                 │
           ├──────────┴─────────────────────────────────┤
           │   TOTAL VISUAL TIME: 1.0 + 2.5 = 3.5s     │
           │   AUDIO TIME: 3.5s                         │
           │   RESULT: PERFECT SYNC ✓                   │
           └───────────────────────────────────────────┘
```

### Injection Process

```
┌─────────────────────────────────────────────────────────────────┐
│                   AUDIO INJECTION PROCESS                        │
└─────────────────────────────────────────────────────────────────┘

STEP 1: Scan code for audio references
        FIND: add_sound("scene_1_title.wav")
        
STEP 2: Identify element type
        EXTRACT: scene=1, element=title
        
STEP 3: Look up actual duration
        FIND: audio_durations[1]["title"] = 2.3 seconds
        
STEP 4: Calculate wait time
        COMPUTE: 2.3 - 1.0 = 1.3 seconds
        
STEP 5: Replace placeholder
        BEFORE: wait(2)
        AFTER:  wait(1.3)
```

---

## File Output Structure

```
medias/
│
├── docker_20260108_143052.py          ← Generated animation code
│
├── audio/
│   ├── scene_1_title.wav              ← "What is Docker?"
│   ├── scene_1_definition.wav         ← "Docker is a platform..."
│   ├── scene_1_point1.wav             ← "Lightweight containers"
│   ├── scene_1_point2.wav             ← "Portable deployment"
│   ├── scene_1_point3.wav             ← "Fast scaling"
│   ├── scene_2_title.wav              ← Scene 2 audio...
│   └── ...
│
└── videos/
    └── docker_20260108_143052/
        └── 480p15/
            └── docker_20260108_143052.mp4  ← Final rendered video
```

---

## End of Documentation

This document explains the complete architecture of YT-Agent using pseudocode and diagrams. For setup instructions, see README.md.

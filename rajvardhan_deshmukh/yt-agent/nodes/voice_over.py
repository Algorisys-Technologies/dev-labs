# nodes/voice_over.py
# Voice-over generation node with per-line audio sync

import os
from nodes.base import BaseAppNode
from utilities import generate_audio, generate_audio_edge, hash_narration, get_audio_duration


class VoiceOverNode(BaseAppNode):
    """
    Generate voice-over audio files with PER-LINE SYNC.
    Each visual element (title, definition, point1-3) gets its own audio file.
    This enables perfect audio-video synchronization.
    """
    
    def __init__(self):
        super().__init__()
        from nodes.review import ReviewNode
        self.next(ReviewNode(), "next")
    
    def exec(self, shared):
        narrations = shared.get("narrations", [])
        
        if not narrations:
            print("[VoiceOverNode] WARNING: No narrations found! Skipping TTS generation.")
            shared["voice_over_files"] = {}
            shared["audio_durations"] = {}
            return "next"
        
        # Create audio directory inside medias folder
        audio_dir = os.path.join("medias", "audio")
        os.makedirs(audio_dir, exist_ok=True)
        
        # Clear old audio files to prevent overlap from previous video
        import glob
        old_audio_files = glob.glob(os.path.join(audio_dir, "scene_*.wav"))
        old_cache_files = glob.glob(os.path.join(audio_dir, ".cache_scene_*.txt"))
        if old_audio_files or old_cache_files:
            print(f"[VoiceOverNode] Clearing {len(old_audio_files)} old audio files...")
            for f in old_audio_files + old_cache_files:
                os.remove(f)
        
        # Save all narrations to a text file
        transcript_file = os.path.join(audio_dir, "audio_transcripts.txt")
        with open(transcript_file, "w", encoding="utf-8") as f:
            f.write("=" * 70 + "\n")
            f.write("AUDIO TRANSCRIPTS (Per-Line Audio Sync)\n")
            f.write("=" * 70 + "\n\n")
            for scene in narrations:
                scene_id = scene.get('scene_id', '?')
                f.write(f"--- Scene {scene_id} ---\n")
                f.write(f"TITLE: {scene.get('title', '')}\n")
                f.write(f"DEFINITION: {scene.get('definition', '')}\n")
                f.write(f"POINT1: {scene.get('point1', '')}\n")
                f.write(f"POINT2: {scene.get('point2', '')}\n")
                f.write(f"POINT3: {scene.get('point3', '')}\n\n")
        print(f"[VoiceOverNode] Saved transcripts to {transcript_file}")
        
        # ====== TTS Engine Selection ======
        print(f"\n{'='*70}")
        print("🎙️  SELECT TTS ENGINE")
        print(f"{'='*70}")
        print("\nChoose your text-to-speech engine:")
        print("  [1] ⚡ Edge TTS (FAST) - Microsoft voices, requires internet")
        print("  [2] 🎭 Chatterbox (HIGH QUALITY) - AI voice, local GPU")
        print("")
        
        tts_choice = input("Your choice [1/2] (default: 1): ").strip()
        use_edge_tts = tts_choice != "2"
        
        if use_edge_tts:
            print("\n✅ Using Edge TTS (fast mode)")
            print("\nAvailable voices:")
            print("  [1] en-US-GuyNeural (male, American)")
            print("  [2] en-US-AriaNeural (female, American)")
            print("  [3] en-GB-RyanNeural (male, British)")
            print("  [4] en-IN-NeerjaNeural (female, Indian)")
            voice_choice = input("Select voice [1-4] (default: 1): ").strip()
            
            voice_map = {
                "1": "en-US-GuyNeural",
                "2": "en-US-AriaNeural", 
                "3": "en-GB-RyanNeural",
                "4": "en-IN-NeerjaNeural"
            }
            selected_voice = voice_map.get(voice_choice, "en-US-GuyNeural")
            print(f"   Selected voice: {selected_voice}\n")
            tts_engine_name = f"Edge TTS ({selected_voice})"
        else:
            print("\n✅ Using Chatterbox (high quality mode)")
            selected_voice = None
            tts_engine_name = "Chatterbox AI"
        
        # Element types to generate audio for
        elements = ['title', 'definition', 'point1', 'point2', 'point3']
        
        # Dict to store audio paths: {scene_id: {element: path}}
        audio_files = {}
        audio_durations = {}
        
        total_files = len(narrations) * len(elements)
        print(f"\n{'='*70}")
        print("🎙️  PER-LINE VOICE-OVER GENERATION")
        print(f"{'='*70}")
        print(f"Generating {total_files} audio files ({len(narrations)} scenes × 5 elements)...\n")
        
        for scene in narrations:
            scene_id = scene.get('scene_id', 1)
            audio_files[scene_id] = {}
            audio_durations[scene_id] = {}
            
            print(f"📍 Scene {scene_id}:")
            
            for element in elements:
                text = scene.get(element, '')
                if not text:
                    print(f"   ⚠️  {element}: Empty text, skipping")
                    audio_files[scene_id][element] = None
                    audio_durations[scene_id][element] = 2.0  # Default
                    continue
                
                audio_path = os.path.join(audio_dir, f"scene_{scene_id}_{element}.wav")
                cache_file = os.path.join(audio_dir, f".cache_scene_{scene_id}_{element}.txt")
                
                cache_key = f"{text}|{tts_engine_name}"
                narration_hash = hash_narration(cache_key)
                
                # Check cache
                if os.path.exists(audio_path) and os.path.exists(cache_file):
                    with open(cache_file, 'r', encoding='utf-8') as f:
                        cached_hash = f.read().strip()
                    
                    if cached_hash == narration_hash:
                        duration = get_audio_duration(audio_path)
                        audio_files[scene_id][element] = audio_path
                        audio_durations[scene_id][element] = duration
                        print(f"   ✅ {element}: cached ({duration:.1f}s)")
                        continue
                
                # Generate new audio
                print(f"   🎤 {element}: \"{text[:50]}{'...' if len(text) > 50 else ''}\"")
                
                try:
                    if use_edge_tts:
                        generate_audio_edge(text, audio_path, voice=selected_voice)
                    else:
                        generate_audio(text, audio_path, max_retries=3)
                    
                    # Save cache
                    with open(cache_file, 'w', encoding='utf-8') as f:
                        f.write(narration_hash)
                    
                    # Get duration
                    duration = get_audio_duration(audio_path)
                    audio_files[scene_id][element] = audio_path
                    audio_durations[scene_id][element] = duration
                    print(f"      ✓ Generated ({duration:.1f}s)")
                    
                except Exception as e:
                    print(f"      ✗ ERROR: {e}")
                    audio_files[scene_id][element] = None
                    audio_durations[scene_id][element] = 2.0
            
            print("")
        
        shared["voice_over_files"] = audio_files
        shared["audio_durations"] = audio_durations
        
        # Summary
        total_generated = sum(
            1 for scene in audio_files.values() 
            for f in scene.values() if f is not None
        )
        print(f"{'='*70}")
        print(f"✅ Voice-over generation complete: {total_generated}/{total_files} files generated")
        print(f"{'='*70}\n")
        
        return "next"

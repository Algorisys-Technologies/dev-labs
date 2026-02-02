# utilities/tts.py
# Text-to-Speech functions

import hashlib


def hash_narration(text: str) -> str:
    """
    Create hash of narration text for cache validation.
    """
    return hashlib.md5(text.encode('utf-8')).hexdigest()


def get_audio_duration(audio_path: str) -> float:
    """
    Get duration of audio file in seconds.
    """
    try:
        import torchaudio
        waveform, sample_rate = torchaudio.load(audio_path)
        duration = waveform.shape[1] / sample_rate
        return duration
    except Exception as e1:
        try:
            import wave
            with wave.open(audio_path, 'r') as wav_file:
                frames = wav_file.getnframes()
                rate = wav_file.getframerate()
                duration = frames / float(rate)
            return duration
        except Exception as e2:
            print(f"[WARNING] Could not read audio duration: {e1}")
            return 20.0


def generate_audio(narration_text: str, output_path: str, max_retries: int = 3) -> str:
    """
    Generate audio file from narration text using AI Chatterbox TTS (local).
    """
    import time
    import torch
    import scipy.io.wavfile as wavfile
    import numpy as np
    
    global _chatterbox_model, _chatterbox_loaded
    
    if '_chatterbox_model' not in globals():
        _chatterbox_model = None
        _chatterbox_loaded = False
    
    last_exception = None
    for attempt in range(max_retries):
        try:
            print(f"[TTS] Attempt {attempt + 1}/{max_retries}: Generating audio...")
            
            if not _chatterbox_loaded:
                print("[TTS] Loading AI Chatterbox model (first time only)...")
                try:
                    from chatterbox.tts import ChatterboxTTS
                    
                    device = "cuda" if torch.cuda.is_available() else "cpu"
                    print(f"[TTS] Using device: {device}")
                    
                    _chatterbox_model = ChatterboxTTS.from_pretrained(device=device)
                    _chatterbox_loaded = True
                    print("[TTS] Model loaded successfully!")
                    
                except ImportError:
                    raise ImportError(
                        "AI Chatterbox not installed. Run: pip install chatterbox-tts"
                    )
            
            wav = _chatterbox_model.generate(narration_text)
            
            wav_numpy = wav.cpu().numpy().squeeze()
            wav_normalized = wav_numpy / np.max(np.abs(wav_numpy)) if np.max(np.abs(wav_numpy)) > 0 else wav_numpy
            wav_int16 = (wav_normalized * 32767).astype(np.int16)
            
            wavfile.write(output_path, _chatterbox_model.sr, wav_int16)
            
            print(f"[TTS] Success! Audio saved to: {output_path}")
            return output_path
        
        except Exception as e:
            last_exception = e
            print(f"[TTS] Attempt {attempt + 1} failed: {e}")
            
            if attempt < max_retries - 1:
                wait_time = 2 ** attempt
                print(f"[TTS] Retrying in {wait_time} seconds...")
                time.sleep(wait_time)
    
    raise Exception(
        f"TTS generation failed after {max_retries} attempts. "
        f"Last error: {last_exception}"
    )


def generate_audio_edge(narration_text: str, output_path: str, voice: str = "en-US-GuyNeural") -> str:
    """
    Generate audio file from narration text using Microsoft Edge TTS (fast, free, online).
    
    Voice options:
        - en-US-GuyNeural (male, American)
        - en-US-AriaNeural (female, American)
        - en-GB-RyanNeural (male, British)
        - en-IN-NeerjaNeural (female, Indian)
    """
    import asyncio
    import edge_tts
    import os
    
    async def _generate():
        mp3_path = output_path.replace('.wav', '.mp3')
        
        communicate = edge_tts.Communicate(narration_text, voice)
        await communicate.save(mp3_path)
        
        try:
            from pydub import AudioSegment
            audio = AudioSegment.from_mp3(mp3_path)
            audio.export(output_path, format="wav")
            os.remove(mp3_path)
        except ImportError:
            import subprocess
            subprocess.run([
                'ffmpeg', '-i', mp3_path, '-acodec', 'pcm_s16le', 
                '-ar', '24000', output_path, '-y'
            ], capture_output=True)
            os.remove(mp3_path)
        
        return output_path
    
    try:
        loop = asyncio.get_event_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
    
    result = loop.run_until_complete(_generate())
    print(f"[TTS-Edge] Audio saved to: {output_path}")
    return result

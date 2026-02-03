# nodes/manim_coder.py
# Manim code generation with per-element audio sync

import os
import re
from datetime import datetime
from nodes.base import BaseAppNode
from utilities import call_llm_text, extract_code, get_audio_duration
from prompts import MANIM_CODER_PROMPT, CODE_VALIDATOR_PROMPT


def inject_audio_durations(code: str, audio_durations: dict) -> str:
    """
    Inject actual audio durations into wait() calls for perfect sync.
    Scans for wait() calls after add_sound() and replaces with actual duration.
    """
    if not audio_durations:
        print("[AudioSync] No audio durations provided, skipping injection")
        return code
    
    lines = code.split('\n')
    new_lines = []
    current_scene = 0
    current_element = None
    
    for i, line in enumerate(lines):
        # Detect which audio file is playing
        if 'self.add_sound(' in line:
            match = re.search(r'scene_(\d+)_(\w+)\.wav', line)
            if match:
                current_scene = int(match.group(1))
                current_element = match.group(2)
        
        # Look for wait() after an animation
        if 'self.wait(' in line and current_element and current_scene > 0:
            if current_scene in audio_durations:
                scene_durations = audio_durations[current_scene]
                if current_element in scene_durations:
                    duration = scene_durations[current_element]
                    # Calculate wait time = audio_duration - animation_time (assume 1s)
                    # Minimum 0.5s wait
                    wait_time = max(0.5, duration - 1.0)
                    
                    # Replace the wait time
                    new_line = re.sub(
                        r'self\.wait\([^)]+\)',
                        f'self.wait({wait_time:.1f})',
                        line
                    )
                    new_line = new_line.rstrip() + f'  # Audio: {duration:.1f}s'
                    new_lines.append(new_line)
                    print(f"[AudioSync] Scene {current_scene} {current_element}: wait({wait_time:.1f}s)")
                    current_element = None  # Reset after using
                    continue
        
        new_lines.append(line)
    
    return '\n'.join(new_lines)


def fix_placeholder_text(code: str) -> str:
    """Detect and warn about placeholder text in generated code."""
    placeholder_patterns = [
        (r'"Some text"', 'PLACEHOLDER: "Some text"'),
        (r'"Definition text here"', 'PLACEHOLDER: "Definition text here"'),
        (r'"Title Here"', 'PLACEHOLDER: "Title Here"'),
        (r'"Point \d+ from KEY_CONTENT"', 'PLACEHOLDER: "Point N from KEY_CONTENT"'),
        (r'"• Point \d+"', 'PLACEHOLDER: "• Point N"'),
    ]
    
    found_placeholders = []
    for pattern, name in placeholder_patterns:
        if re.search(pattern, code):
            found_placeholders.append(name)
    
    if found_placeholders:
        print("\n" + "="*70)
        print("⚠️  WARNING: PLACEHOLDER TEXT DETECTED!")
        print("="*70)
        for p in found_placeholders:
            print(f"   Found: {p}")
        print("\nThe generated code may need manual review.")
        print("="*70 + "\n")
    
    return code


def fix_text_overflow(code: str) -> str:
    """Post-process generated Manim code to fix text overflow and cleanup."""
    
    # Unicode to LaTeX mapping
    unicode_to_latex = {
        'α': r'\alpha', 'β': r'\beta', 'γ': r'\gamma', 'δ': r'\delta',
        'ε': r'\epsilon', 'θ': r'\theta', 'λ': r'\lambda', 'μ': r'\mu',
        'π': r'\pi', 'σ': r'\sigma', 'τ': r'\tau', 'φ': r'\phi',
        'ω': r'\omega', 'Σ': r'\Sigma', 'Δ': r'\Delta', 'Ω': r'\Omega',
        '²': r'^2', '³': r'^3', '±': r'\pm', '×': r'\times',
        '÷': r'\div', '≠': r'\neq', '≤': r'\leq', '≥': r'\geq',
        '∞': r'\infty', '∑': r'\sum', '∫': r'\int', '√': r'\sqrt',
        '∂': r'\partial', '∇': r'\nabla',
    }
    
    def replace_unicode_in_mathtex(match):
        content = match.group(1)
        for unicode_char, latex_cmd in unicode_to_latex.items():
            content = content.replace(unicode_char, latex_cmd)
        return f'MathTex(r"{content}"'
    
    code = re.sub(r'MathTex\(r?"([^"]*)"', replace_unicode_in_mathtex, code)
    
    # Fix definition boxes width and height
    code = re.sub(r'RoundedRectangle\(width=[\d.]+, height=[\d.]+', 'RoundedRectangle(width=13, height=1.5', code)

    
    # ===== FIX: Scale text to fit on screen =====
    # Add scale_to_fit_width to definition to prevent overflow
    # This will shrink long text to fit within the 12-unit width
    code = re.sub(
        r'(definition\s*=\s*Text\([^)]+\))\.move_to',
        r'\1.scale_to_fit_width(12).move_to',
        code
    )
    # Also handle cases where move_to is not immediately after
    code = re.sub(
        r'(definition\s*=\s*Text\([^)]+\))(\s*\n)',
        r'\1.scale_to_fit_width(12)\2',
        code
    )
    
    # Add scale_to_fit_width to key points VGroup 
    code = re.sub(
        r'(key_points\s*=\s*VGroup\([^)]+\))\.arrange',
        r'\1.scale_to_fit_width(12).arrange',
        code
    )
    
    # ===== Ensure consistent font sizes =====
    # Set definition font_size to 22 (same as key points)
    code = re.sub(r'(definition\s*=\s*Text\([^)]+)font_size=\d+', r'\1font_size=22', code)
    
    # Ensure key points use font_size=22 consistently
    code = re.sub(r'(Text\("• [^"]+")(\))', r'\1, font_size=22)', code)
    
    # ===== FIX: Enforce exactly 3 key points =====
    # Remove any point4, point5, etc. audio references (only point1-3 are generated)
    code = re.sub(r'^.*scene_\d+_point[4-9]\.wav.*$\n?', '', code, flags=re.MULTILINE)
    
    # Remove extra key_points[3], key_points[4], etc. animation lines
    code = re.sub(r'^.*key_points\[[3-9]\].*$\n?', '', code, flags=re.MULTILINE)
    
    # Also remove the 4th+ Text entries from VGroup definitions
    # Match Text("...") entries after the 3rd one in VGroup
    def limit_vgroup_to_3(match):
        """Keep only first 3 Text items in a VGroup."""
        full_match = match.group(0)
        # Find all Text("...") entries
        text_pattern = r'Text\([^)]+\)'
        texts = re.findall(text_pattern, full_match)
        if len(texts) <= 3:
            return full_match
        # Rebuild with only first 3
        vgroup_start = 'key_points = VGroup(\n'
        items = []
        for i, t in enumerate(texts[:3]):
            items.append(f'            {t}')
        vgroup_body = ',\n'.join(items)
        vgroup_end = '\n        ).arrange(DOWN, aligned_edge=LEFT, buff=0.3)'
        return vgroup_start + vgroup_body + vgroup_end
    
    code = re.sub(
        r'key_points\s*=\s*VGroup\([^)]*\)\.arrange\(DOWN,\s*aligned_edge=LEFT,\s*buff=0\.3\)',
        limit_vgroup_to_3,
        code,
        flags=re.DOTALL
    )

    # Remove forbidden elements

    useless_vars = ['diagram', 'visual', 'neural_network', 'timeline', 'flowchart']
    for var in useless_vars:
        code = re.sub(rf'^\s*{var}\s*=\s*.+$\n?', '', code, flags=re.MULTILINE)
        code = re.sub(rf'^\s*self\.play\([^)]*{var}[^)]*\)\s*$\n?', '', code, flags=re.MULTILINE)
    
    code = re.sub(r'^.*\bLine\s*\([^)]*\).*$\n?', '', code, flags=re.MULTILINE)
    code = re.sub(r'\bShowCreation\b', 'Create', code)
    
    # Remove equation_box
    code = re.sub(r'^\s*equation_box\s*=\s*RoundedRectangle[^\n]*\n?', '', code, flags=re.MULTILINE)
    code = re.sub(r'FadeIn\(equation_box\),?\s*', '', code)
    
    # Ensure import is present
    if 'from manim import' not in code:
        code = 'from manim import *\n\n' + code
    
    # Fix class names
    code = re.sub(r'class\s+\w+\s*\(Scene\)', 'class VideoScene(Scene)', code)
    
    # ===== FIX: Remove duplicate class definitions =====
    # LLM sometimes generates multiple "class VideoScene(Scene):" blocks
    # We need to merge them into one, or keep only what's inside one construct()
    lines = code.split('\n')
    class_line_indices = [i for i, line in enumerate(lines) if re.match(r'^class\s+VideoScene\s*\(Scene\)\s*:', line)]
    
    if len(class_line_indices) > 1:
        # Keep everything up to line before 2nd class definition
        # This preserves the first class with all its scenes in construct()
        second_class_start = class_line_indices[1]
        lines = lines[:second_class_start]
        code = '\n'.join(lines)
    
    # ===== FIX: Remove any module-level executable code =====
    # LLM sometimes adds lines like: "SomeClass().play()" at the bottom
    code = re.sub(r'^\w+\(\)\.(?:play|render|construct)\(\)\s*$', '', code, flags=re.MULTILINE)
    
    # Remove "# Run the scene" comments and invalid class references
    code = re.sub(r'^#\s*Run the scene.*$', '', code, flags=re.MULTILINE)
    code = re.sub(r'^#\s*Create a scene.*$', '', code, flags=re.MULTILINE)
    
    # Remove any lines with undefined scene class references like CI_CD_Scene_1()
    code = re.sub(r'^.*\w+_Scene_\d+\(\).*$\n?', '', code, flags=re.MULTILINE)
    
    # Clean up blank lines
    code = re.sub(r'\n\s*\n\s*\n+', '\n\n', code)
    code = re.sub(r',\s*\)', ')', code)
    
    # Remove trailing whitespace
    code = code.rstrip() + '\n'
    
    return code



class ManimCoderNode(BaseAppNode):
    """Generate Manim code with per-element audio sync."""
    
    def __init__(self):
        super().__init__()
        from nodes.output import OutputNode
        self.next(OutputNode(), "next")

    def exec(self, shared):
        scene_plan = shared["scene_plan"]
        audio_durations = shared.get("audio_durations", {})
        
        # Step 1: Generate initial code
        print("[ManimCoderNode] Step 1: Generating Manim code via LLM...")
        raw_output = call_llm_text(
            MANIM_CODER_PROMPT,
            f"Scene Plan:\n{scene_plan}"
        )
        
        initial_code = extract_code(raw_output)
        print(f"[ManimCoderNode] Initial code: {len(initial_code.split(chr(10)))} lines")
        
        # Step 2: Validate and fix code
        print("[ManimCoderNode] Step 2: Validating and fixing code via LLM...")
        validation_output = call_llm_text(CODE_VALIDATOR_PROMPT, initial_code)
        validated_code = extract_code(validation_output)
        
        if len(validated_code.strip()) < 100:
            print("[ManimCoderNode] Warning: Validation returned empty code, using initial code")
            validated_code = initial_code
        else:
            print(f"[ManimCoderNode] Validated code: {len(validated_code.split(chr(10)))} lines")
        
        # Step 3: Apply regex cleanup
        print("[ManimCoderNode] Step 3: Applying regex cleanup...")
        manim_code = fix_text_overflow(validated_code)
        
        # Step 3b: Check for placeholders
        print("[ManimCoderNode] Step 3b: Checking for placeholder text...")
        manim_code = fix_placeholder_text(manim_code)
        
        # Step 4: Inject actual audio durations for perfect sync
        print("[ManimCoderNode] Step 4: Injecting audio durations for perfect sync...")
        if audio_durations:
            manim_code = inject_audio_durations(manim_code, audio_durations)
        else:
            print("[ManimCoderNode] No audio durations provided, using default wait times")
        
        # Print debug output
        print("\n" + "="*70)
        print("FINAL MANIM CODE")
        print("="*70)
        print(manim_code)
        print("="*70 + "\n")
        
        # Create unique filename in medias folder
        user_query = shared.get("user_query", "video")
        sanitized_name = re.sub(r'[^\w\s-]', '', user_query.lower())
        sanitized_name = re.sub(r'[\s]+', '_', sanitized_name.strip())[:50]
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        video_name = f"{sanitized_name}_{timestamp}"
        
        # Save to medias folder (keeps all generated files together)
        output_dir = "medias"
        os.makedirs(output_dir, exist_ok=True)
        output_filename = os.path.join(output_dir, f"{video_name}.py")
        
        # Save to file
        with open(output_filename, "w", encoding="utf-8") as f:
            f.write(manim_code)
        
        shared["manim_code"] = manim_code
        shared["output_file"] = output_filename
        shared["video_name"] = video_name
        
        print(f"[ManimCoderNode] Generated {len(manim_code.split(chr(10)))} lines of Manim code")
        print(f"[ManimCoderNode] Saved to {output_filename}")
        return "next"

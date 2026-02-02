# utilities/parsing.py
# Parsing and extraction functions

import re
import json


def extract_json(text: str):
    """
    Extracts JSON from text that might contain markdown code blocks.
    Handles ```json...``` formatting and plain JSON (objects or arrays).
    """
    code_block_pattern = r'```(?:json)?\s*(\{.*?\}|\[.*?\])\s*```'
    match = re.search(code_block_pattern, text, re.DOTALL)
    
    if match:
        json_str = match.group(1)
    else:
        array_pattern = r'\[.*\]'
        match = re.search(array_pattern, text, re.DOTALL)
        if match:
            json_str = match.group(0)
        else:
            object_pattern = r'\{.*\}'
            match = re.search(object_pattern, text, re.DOTALL)
            if match:
                json_str = match.group(0)
            else:
                json_str = text
    
    # Fix invalid escape sequences that LLMs sometimes output
    # \* is not valid JSON - remove the backslash
    json_str = re.sub(r'\\([^"\\\/bfnrtu])', r'\1', json_str)
    
    return json.loads(json_str)


def extract_code(text: str) -> str:
    """
    Extracts Python code from a string, handling markdown code blocks.
    """
    if not text:
        return ""
    
    pattern = r"```(?:python)?\n(.*?)```"
    match = re.search(pattern, text, re.DOTALL)
    if match:
        return match.group(1).strip()
    
    return text.strip().replace("`", "")


def parse_narrations(scene_plan_text: str) -> list:
    """
    Extract per-line NARRATION blocks from scene plan text.
    Returns a list of dicts, one per scene, with keys:
    - title, definition, point1, point2, point3
    
    Args:
        scene_plan_text: Raw scene plan output from LLM
    
    Returns:
        List of dicts with separate audio texts per element
    """
    scenes = []
    lines = scene_plan_text.strip().split('\n')
    
    current_scene = {}
    scene_number = 0
    
    # Regex to detect scene headers with various markdown formats:
    # "Scene 1:", "**Scene 1:**", "### Scene 1:", "---\nScene 1:", etc.
    scene_header_pattern = re.compile(r'^[\*#\-\s]*Scene\s+(\d+)\s*[:\*\-]', re.IGNORECASE)
    
    for line in lines:
        stripped = line.strip()
        
        # Detect new scene with flexible pattern
        scene_match = scene_header_pattern.match(stripped)
        if scene_match:
            if current_scene:
                scenes.append(current_scene)
            scene_number = int(scene_match.group(1))
            current_scene = {
                'scene_id': scene_number,
                'title': '',
                'definition': '',
                'point1': '',
                'point2': '',
                'point3': ''
            }
        
        # Parse per-element narrations
        elif stripped.startswith('TITLE_AUDIO:'):
            current_scene['title'] = stripped.split('TITLE_AUDIO:', 1)[1].strip()
        elif stripped.startswith('DEFINITION_AUDIO:'):
            current_scene['definition'] = stripped.split('DEFINITION_AUDIO:', 1)[1].strip()
        elif stripped.startswith('POINT1_AUDIO:'):
            current_scene['point1'] = stripped.split('POINT1_AUDIO:', 1)[1].strip()
        elif stripped.startswith('POINT2_AUDIO:'):
            current_scene['point2'] = stripped.split('POINT2_AUDIO:', 1)[1].strip()
        elif stripped.startswith('POINT3_AUDIO:'):
            current_scene['point3'] = stripped.split('POINT3_AUDIO:', 1)[1].strip()
    
    # Don't forget the last scene
    if current_scene:
        scenes.append(current_scene)
    
    return scenes


def parse_scene_plan(text: str) -> list:
    """
    Parses text-based scene plan into a list of scene dictionaries.
    """
    scenes = []
    current_scene = {}
    current_section = None
    key_points = []
    
    lines = text.strip().split('\n')
    
    for line in lines:
        line_stripped = line.strip()
        
        if line_stripped.startswith('SCENE '):
            if current_scene:
                if key_points:
                    current_scene['key_points'] = key_points
                scenes.append(current_scene)
            try:
                scene_id = int(line_stripped.split('SCENE ')[1])
                current_scene = {'scene_id': scene_id}
                key_points = []
                current_section = None
            except:
                current_scene = {'scene_id': len(scenes) + 1}
        
        elif line_stripped.startswith('Title:'):
            current_scene['title'] = line_stripped.split('Title:', 1)[1].strip()
            current_section = None
        
        elif line_stripped.startswith('Duration:'):
            duration_text = line_stripped.split('Duration:', 1)[1].strip()
            try:
                duration = int(''.join(filter(str.isdigit, duration_text)))
                current_scene['duration_sec'] = duration
            except:
                current_scene['duration_sec'] = 20
            current_section = None
        
        elif line_stripped.startswith('Teaching Goal:'):
            current_scene['teaching_goal'] = line_stripped.split('Teaching Goal:', 1)[1].strip()
            current_section = None
        
        elif line_stripped.startswith('Visual Elements:'):
            current_section = 'visuals'
        
        elif current_section == 'visuals':
            if line_stripped.startswith('Equation:'):
                eq = line_stripped.split('Equation:', 1)[1].strip()
                current_scene['equation'] = None if eq.lower() in ['none', ''] else eq
            elif line_stripped.startswith('Diagram:'):
                diag = line_stripped.split('Diagram:', 1)[1].strip()
                current_scene['diagram'] = None if diag.lower() in ['none', ''] else diag
            elif line_stripped.startswith('Code:'):
                code = line_stripped.split('Code:', 1)[1].strip()
                current_scene['code'] = None if code.lower() in ['none', ''] else code
            elif line_stripped.startswith('Animation:'):
                anim = line_stripped.split('Animation:', 1)[1].strip()
                current_scene['animation'] = anim if anim else None
            elif line_stripped.startswith('Key Points:'):
                current_section = 'key_points'
        
        elif current_section == 'key_points':
            if line_stripped.startswith('- '):
                key_points.append(line_stripped[2:])
        
        elif line_stripped.startswith('Description:'):
            current_scene['description'] = line_stripped.split('Description:', 1)[1].strip()
            current_section = None
    
    if current_scene:
        if key_points:
            current_scene['key_points'] = key_points
        scenes.append(current_scene)
    
    return scenes

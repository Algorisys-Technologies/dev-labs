# nodes/output.py
# Final output display node

from nodes.base import BaseAppNode


class OutputNode(BaseAppNode):
    """Display final output and render instructions."""
    
    def exec(self, shared):
        output = shared.get("draft_output", {})
        
        print("\n" + "="*60)
        print("VIDEO CONTENT PLAN")
        print("="*60)
        
        print(f"\nTOPIC: {output.get('topic', 'N/A')}")
        print(f"\nTARGET AUDIENCE: {output.get('audience', 'N/A')}")
        print(f"\nINTENT: {output.get('intent', 'N/A')}")
        
        print("\nCONTENT OUTLINE:")
        print("-" * 60)
        
        outline = output.get('outline', {})
        for section_name, section_data in outline.items():
            print(f"\n{section_name}")
            
            if isinstance(section_data, dict):
                description = section_data.get('description', '')
                if description:
                    print(f"  > {description}")
                
                subtopics = section_data.get('subtopics', [])
                if subtopics:
                    for subtopic in subtopics:
                        print(f"    - {subtopic}")
            else:
                print(f"  > {section_data}")
        
        print("\n" + "="*60)
        
        # Display scene plan if available
        scene_plan = shared.get("scene_plan")
        if scene_plan:
            print("\nMANIM SCENE PLAN")
            print("="*60)
            
            if isinstance(scene_plan, list):
                for scene in scene_plan:
                    scene_id = scene.get('scene_id', '?')
                    title = scene.get('title', 'Untitled')
                    duration = scene.get('duration_sec', 0)
                    description = scene.get('description', '')
                    
                    print(f"\n[Scene {scene_id}] {title} ({duration}s)")
                    if description:
                        print(f"  {description}")
                        
            print("\n" + "="*60 + "\n")
        else:
            print("\n")
        
        # Display generated code info
        output_file = shared.get("output_file")
        if output_file:
            manim_code = shared.get("manim_code", "")
            video_name = shared.get("video_name", "video")
            lines = len(manim_code.split('\n'))
            
            print("GENERATED MANIM CODE")
            print("="*60)
            print(f"File: {output_file}")
            print(f"Lines: {lines}")
            print(f"Size: {len(manim_code)} characters")
            print("\nTo render:")
            print(f"  manim -pql --media_dir ./medias -o {video_name} {output_file} VideoScene")
            print("="*60 + "\n")
        
        return None

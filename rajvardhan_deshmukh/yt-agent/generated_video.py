from manim import *

class VideoScene(Scene):
    def construct(self):
        # Scene 1: What are Atom of Thoughts?
        self.add_sound("audio/scene_1.wav")
        
        title = Text("What are Atom of Thoughts?", font_size=54, color=BLUE).scale_to_fit_width(13).to_edge(UP, buff=0.5)
        definition_box = RoundedRectangle(width=13, height=2, color=BLUE).next_to(title, DOWN, buff=0.5)
        definition = Text("Atom of thoughts are the fundamental units of thought that make up our mental processes.", font_size=24).scale_to_fit_width(12).move_to(definition_box)
        key_points = VGroup(
            Text("• Building blocks of cognitive experiences", font_size=18),
            Text("• Influence perception, processing, and response to information", font_size=18),
            Text("• Crucial in understanding human thought and behavior", font_size=18)
        ).arrange(DOWN, aligned_edge=LEFT, buff=0.3)
        key_points.next_to(definition_box, DOWN, buff=0.5)
        
        self.play(Write(title), run_time=1)
        self.wait(0.5)
        self.play(FadeIn(definition_box), Write(definition), run_time=1.5)
        self.wait(1.5)  # Brief pause for definition
        self.play(Write(key_points[0]), run_time=1)
        self.wait(1)  # Brief pause for point 1
        self.play(Write(key_points[1]), run_time=1)
        self.wait(1)  # Brief pause for point 2
        self.play(Write(key_points[2]), run_time=1)
        self.wait(2)  # Final pause before transition
        self.wait(6.8)  # Sync: audio=18.3s
        self.play(*[FadeOut(mob) for mob in self.mobjects], run_time=0.5)
        
        # Scene 2: Relationship with Cognitive Biases and Heuristics
        self.add_sound("audio/scene_2.wav")
        
        title = Text("Atom of Thoughts and Cognitive Biases", font_size=54, color=BLUE).scale_to_fit_width(13).to_edge(UP, buff=0.5)
        definition_box = RoundedRectangle(width=13, height=2, color=BLUE).next_to(title, DOWN, buff=0.5)
        definition = Text("Cognitive biases and heuristics are mental shortcuts that influence our decision-making processes.", font_size=24).scale_to_fit_width(12).move_to(definition_box)
        key_points = VGroup(
            Text("• Atom of thoughts can be influenced by cognitive biases and heuristics", font_size=18),
            Text("• Biases can lead to inaccurate or incomplete information", font_size=18),
            Text("• Understanding the relationship is crucial for informed decision-making", font_size=18)
        ).arrange(DOWN, aligned_edge=LEFT, buff=0.3)
        key_points.next_to(definition_box, DOWN, buff=0.5)
        
        self.play(Write(title), run_time=1)
        self.wait(0.5)
        self.play(FadeIn(definition_box), Write(definition), run_time=1.5)
        self.wait(1.5)  # Brief pause for definition
        self.play(Write(key_points[0]), run_time=1)
        self.wait(1)  # Brief pause for point 1
        self.play(Write(key_points[1]), run_time=1)
        self.wait(1)  # Brief pause for point 2
        self.play(Write(key_points[2]), run_time=1)
        self.wait(2)  # Final pause before transition
        self.wait(2.4)  # Sync: audio=13.9s
        self.play(*[FadeOut(mob) for mob in self.mobjects], run_time=0.5)
        
        # Scene 3: Prompting Techniques
        self.add_sound("audio/scene_3.wav")
        
        title = Text("Prompting Techniques", font_size=54, color=BLUE).scale_to_fit_width(13).to_edge(UP, buff=0.5)
        definition_box = RoundedRectangle(width=13, height=2, color=BLUE).next_to(title, DOWN, buff=0.5)
        definition = Text("Prompting techniques are strategies used to elicit atom of thoughts in individuals.", font_size=24).scale_to_fit_width(12).move_to(definition_box)
        key_points = VGroup(
            Text("• Free association involves freely associating words or ideas", font_size=18),
            Text("• Mind mapping involves creating visual maps of ideas and concepts", font_size=18),
            Text("• Stream-of-consciousness writing involves writing down thoughts without stopping or editing", font_size=18)
        ).arrange(DOWN, aligned_edge=LEFT, buff=0.3)
        key_points.next_to(definition_box, DOWN, buff=0.5)
        
        self.play(Write(title), run_time=1)
        self.wait(0.5)
        self.play(FadeIn(definition_box), Write(definition), run_time=1.5)
        self.wait(1.5)  # Brief pause for definition
        self.play(Write(key_points[0]), run_time=1)
        self.wait(1)  # Brief pause for point 1
        self.play(Write(key_points[1]), run_time=1)
        self.wait(1)  # Brief pause for point 2
        self.play(Write(key_points[2]), run_time=1)
        self.wait(2)  # Final pause before transition
        self.play(*[FadeOut(mob) for mob in self.mobjects], run_time=0.5)
        
        # Scene 4: Applications in Real-World Scenarios
        self.add_sound("audio/scene_4.wav")
        
        title = Text("Applications of Atom of Thoughts", font_size=54, color=BLUE).scale_to_fit_width(13).to_edge(UP, buff=0.5)
        definition_box = RoundedRectangle(width=13, height=2, color=BLUE).next_to(title, DOWN, buff=0.5)
        definition = Text("Atom of thoughts have numerous applications in real-world scenarios.", font_size=24).scale_to_fit_width(12).move_to(definition_box)
        key_points = VGroup(
            Text("• Therapeutic applications involve using atom of thoughts to treat mental health conditions", font_size=18),
            Text("• Creative problem-solving involves using atom of thoughts to generate new ideas and solutions", font_size=18),
            Text("• Decision-making involves using atom of thoughts to make informed decisions", font_size=18)
        ).arrange(DOWN, aligned_edge=LEFT, buff=0.3)
        key_points.next_to(definition_box, DOWN, buff=0.5)
        
        self.play(Write(title), run_time=1)
        self.wait(0.5)
        self.play(FadeIn(definition_box), Write(definition), run_time=1.5)
        self.wait(1.5)  # Brief pause for definition
        self.play(Write(key_points[0]), run_time=1)
        self.wait(1)  # Brief pause for point 1
        self.play(Write(key_points[1]), run_time=1)
        self.wait(1)  # Brief pause for point 2
        self.play(Write(key_points[2]), run_time=1)
        self.wait(2)  # Final pause before transition
        self.wait(1.5)  # Sync: audio=13.0s
        self.play(*[FadeOut(mob) for mob in self.mobjects], run_time=0.5)
        
        # Scene 5: Challenges and Limitations
        self.add_sound("audio/scene_5.wav")
        
        title = Text("Challenges and Limitations of Atom of Thoughts", font_size=54, color=BLUE).scale_to_fit_width(13).to_edge(UP, buff=0.5)
        definition_box = RoundedRectangle(width=13, height=2, color=BLUE).next_to(title, DOWN, buff=0.5)
        definition = Text("Measuring atom of thoughts can be difficult.", font_size=24).scale_to_fit_width(12).move_to(definition_box)
        key_points = VGroup(
            Text("• Cultural and individual differences can affect the expression and interpretation of atom of thoughts", font_size=18),
            Text("• Measuring atom of thoughts requires careful consideration of these differences", font_size=18),
            Text("• Future research is needed to better understand the challenges and limitations of atom of thoughts", font_size=18)
        ).arrange(DOWN, aligned_edge=LEFT, buff=0.3)
        key_points.next_to(definition_box, DOWN, buff=0.5)
        
        self.play(Write(title), run_time=1)
        self.wait(0.5)
        self.play(FadeIn(definition_box), Write(definition), run_time=1.5)
        self.wait(1.5)  # Brief pause for definition
        self.play(Write(key_points[0]), run_time=1)
        self.wait(1)  # Brief pause for point 1
        self.play(Write(key_points[1]), run_time=1)
        self.wait(1)  # Brief pause for point 2
        self.play(Write(key_points[2]), run_time=1)
        self.wait(2)  # Final pause before transition
        self.play(*[FadeOut(mob) for mob in self.mobjects], run_time=0.5)
        
        # Scene 6: Real-World Applications of Atom of Thoughts
        self.add_sound("audio/scene_6.wav")
        
        title = Text("Real-World Applications of Atom of Thoughts", font_size=54, color=BLUE).scale_to_fit_width(13).to_edge(UP, buff=0.5)
        definition_box = RoundedRectangle(width=13, height=2, color=BLUE).next_to(title, DOWN, buff=0.5)
        definition = Text("Atom of thoughts have numerous real-world applications.", font_size=24).scale_to_fit_width(12).move_to(definition_box)
        key_points = VGroup(
            Text("• Therapeutic applications involve using atom of thoughts to treat mental health conditions", font_size=18),
            Text("• Creative problem-solving involves using atom of thoughts to generate new ideas and solutions", font_size=18),
            Text("• Decision-making involves using atom of thoughts to make informed decisions", font_size=18)
        ).arrange(DOWN, aligned_edge=LEFT, buff=0.3)
        key_points.next_to(definition_box, DOWN, buff=0.5)
        
        self.play(Write(title), run_time=1)
        self.wait(0.5)
        self.play(FadeIn(definition_box), Write(definition), run_time=1.5)
        self.wait(1.5)  # Brief pause for definition
        self.play(Write(key_points[0]), run_time=1)
        self.wait(1)  # Brief pause for point 1
        self.play(Write(key_points[1]), run_time=1)
        self.wait(1)  # Brief pause for point 2
        self.play(Write(key_points[2]), run_time=1)
        self.wait(2)  # Final pause before transition
        self.wait(1.8)  # Sync: audio=13.3s
        self.play(*[FadeOut(mob) for mob in self.mobjects], run_time=0.5)
        
        # Scene 7: Key Takeaway
        self.add_sound("audio/scene_7.wav")
        
        title = Text("Key Takeaway", font_size=54, color=BLUE).scale_to_fit_width(13).to_edge(UP, buff=0.5)
        definition_box = RoundedRectangle(width=13, height=2, color=BLUE).next_to(title, DOWN, buff=0.5)
        definition = Text("Understanding atom of thoughts is crucial in cognitive psychology and neuroscience.", font_size=24).scale_to_fit_width(12).move_to(definition_box)
        key_points = VGroup(
            Text("• Atom of thoughts are the basic units of thought that make up our mental processes", font_size=18),
            Text("• They are influenced by cognitive biases and heuristics", font_size=18),
            Text("• Understanding atom of thoughts can improve mental health, creativity, and decision-making abilities", font_size=18)
        ).arrange(DOWN, aligned_edge=LEFT, buff=0.3)
        key_points.next_to(definition_box, DOWN, buff=0.5)
        
        self.play(Write(title), run_time=1)
        self.wait(0.5)
        self.play(FadeIn(definition_box), Write(definition), run_time=1.5)
        self.wait(1.5)  # Brief pause for definition
        self.play(Write(key_points[0]), run_time=1)
        self.wait(1)  # Brief pause for point 1
        self.play(Write(key_points[1]), run_time=1)
        self.wait(1)  # Brief pause for point 2
        self.play(Write(key_points[2]), run_time=1)
        self.wait(2)  # Final pause before transition
        self.wait(0.7)  # Sync: audio=12.2s
        self.play(*[FadeOut(mob) for mob in self.mobjects], run_time=0.5)
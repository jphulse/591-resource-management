shader_type canvas_item;

uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float tightness : hint_range(0.05, 0.5) = 0.15; // The "Radius"
uniform vec2 flash_offset = vec2(0.8, 0.5);
uniform vec4 flash_color : source_color = vec4(0.4, 0.7, 1.0, 1.0);
uniform float glow_radius_decay : hint_range(1.0, 5.0) = 2.5;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    float d = distance(UV, flash_offset);
    
    // Using our tightness uniform here
    float glow = smoothstep(tightness, 0.0, d);
    
    // Optional: add the power curve for extra "punch"
    glow = pow(glow, glow_radius_decay);

    vec3 bright_flash = mix(tex_color.rgb, flash_color.rgb, flash_intensity * glow);
    COLOR = vec4(bright_flash + (flash_color.rgb * flash_intensity * 0.5), tex_color.a);
}
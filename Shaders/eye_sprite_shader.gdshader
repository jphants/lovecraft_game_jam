shader_type spatial;

uniform sampler2D sprite_sheet;
uniform int columns = 6;
uniform int rows = 5;
uniform int frame = 0;

void fragment() {
    int total_frames = columns * rows;

    int col = frame % columns;
    int row = frame / columns;

    vec2 frame_size = vec2(1.0 / float(columns), 1.0 / float(rows));
    vec2 uv = UV * frame_size;
    uv += vec2(float(col), float(row)) * frame_size;

    ALBEDO = texture(sprite_sheet, uv).rgb;
    ALPHA = texture(sprite_sheet, uv).a;
}

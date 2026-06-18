#version 460

uniform sampler2D gtexture;
uniform int worldTime;

in vec2 texcoord;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

void main() {

    vec4 tex =
        texture(
            gtexture,
            texcoord
        );

    if (tex.a < 0.01) {
        discard;
    }

    outColor0 = tex;
}
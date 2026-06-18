#version 460 compatibility

out vec2 texcoord;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

void main(){
    texcoord=gl_MultiTexCoord0.xy;
    gl_Position=ftransform();
}

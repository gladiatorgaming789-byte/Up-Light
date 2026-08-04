#version 460 compatibility

// Outputs
out vec2 uv;
out vec3 vertexColor;
out vec3 viewNormal;
out vec2 lightmapUV;

void main() {

    uv =
        gl_MultiTexCoord0.xy;

    vertexColor =
        gl_Color.rgb;

    viewNormal =
        normalize(
            gl_NormalMatrix *
            gl_Normal
        );

    lightmapUV =
        (
            gl_TextureMatrix[1] *
            gl_MultiTexCoord2
        ).xy;

    gl_Position =
        gl_ProjectionMatrix *
        gl_ModelViewMatrix *
        gl_Vertex;
}
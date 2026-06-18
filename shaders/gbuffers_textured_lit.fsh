#version 460

uniform sampler2D gtexture;
uniform sampler2D lightmap;

uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform int worldTime;

in vec2 uv;
in vec3 vertexColor;
in vec3 viewNormal;
in vec2 lightmapUV;

layout(location = 0) out vec4 outColor;

const float AMBIENT_LIGHT = 0.45;

void main() {

    vec4 textureColor = texture(gtexture, uv);

    if (textureColor.a < 0.1) {
        discard;
    }

    vec3 lightmapColor =
        texture(lightmap, lightmapUV).rgb;

    vec3 sunDirection =
        normalize(shadowLightPosition);

    float diffuse =
        max(dot(viewNormal, sunDirection), 0.0);

    vec3 worldSunDirection =
        normalize(
            mat3(gbufferModelViewInverse) *
            shadowLightPosition
        );

    float timeOfDay =
        mod(
            float(worldTime),
            24000.0
        );

    float sunsetBlend =
        smoothstep(
            11000.0,
            13000.0,
            timeOfDay
        );

    float sunriseBlend =
        1.0 -
        smoothstep(
            23000.0,
            24000.0,
            timeOfDay
        );

    sunsetBlend =
        max(
            sunsetBlend,
            sunriseBlend
        );

    diffuse *=
        mix(
            1.0,
            0.6,
            sunsetBlend
        );

    float dayFactor =
        clamp(
            sin(
                timeOfDay *
                6.2831853 /
                24000.0
            ) * 0.5 + 0.5,
            0.0,
            1.0
        );

    vec3 moonColor =
        vec3(
            0.35,
            0.45,
            0.70
        );

    vec3 sunriseColor =
        vec3(1.00, 0.35, 0.05);

    vec3 noonColor =
        vec3(1.00, 0.98, 0.92);

    vec3 daylightColor =
        mix(
            sunriseColor,
            noonColor,
            smoothstep(
                0.15,
                0.85,
                dayFactor
            )
        );

    vec3 sunlightColor =
        mix(
            moonColor,
            daylightColor,
            dayFactor
        );

    vec3 finalColor =
        textureColor.rgb *
        vertexColor *
        lightmapColor *
        (
            vec3(AMBIENT_LIGHT) +
            diffuse * 0.65 * sunlightColor
        );

    outColor =
        vec4(finalColor, textureColor.a);
}

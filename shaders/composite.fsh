#version 460

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform int worldTime;
uniform float near;
uniform float far;

in vec2 texcoord;

/* RENDERTARGETS:0 */
layout(location = 0) out vec4 color;

const float TAU = 6.2831853;

float linearizeDepth(float depth) {

    float z =
        depth * 2.0 - 1.0;

    return
        (
            2.0 *
            near *
            far
        ) /
        (
            far +
            near -
            z *
            (
                far -
                near
            )
        );
}

void main() {

    vec4 sceneColor =
        texture(
            colortex0,
            texcoord
        );

    float depth =
        texture(
            depthtex0,
            texcoord
        ).r;

    /*
        depth == 1.0 usually means sky/background.
        Do not fog the sky, since skybasic already handles atmospheric color.
    */
    if (depth >= 0.9999) {
        color =
            sceneColor;

        return;
    }

    float viewDistance =
        linearizeDepth(
            depth
        );

    float timeOfDay =
        mod(
            float(worldTime),
            24000.0
        );

    float rawDayFactor =
        sin(
            timeOfDay *
            TAU /
            24000.0
        ) * 0.5 + 0.5;

    float dayFactor =
        smoothstep(
            0.12,
            0.88,
            rawDayFactor
        );

    float skyTime =
        mod(
            timeOfDay + 2600.0,
            24000.0
        );

    float dawnDuskFactor =
        pow(
            max(
                0.0,
                sin(
                    skyTime *
                    TAU /
                    12000.0
                )
            ),
            2.0
        );

    vec3 dayFogColor =
        vec3(
            0.72,
            0.84,
            1.00
        );

    vec3 nightFogColor =
        vec3(
            0.035,
            0.045,
            0.085
        );

    vec3 dawnDuskFogColor =
        vec3(
            1.00,
            0.58,
            0.30
        );

    vec3 fogColor =
        mix(
            nightFogColor,
            dayFogColor,
            dayFactor
        );

    fogColor =
        mix(
            fogColor,
            dawnDuskFogColor,
            dawnDuskFactor * 0.22
        );

    /*
        Stage 6D: Basic distance fog.

        Starts far enough away that nearby blocks stay clear,
        then slowly blends distant terrain into the sky color.
    */
    float fogStart =
        far * 0.18;

    float fogEnd =
        far * 0.82;

    float fogAmount =
        smoothstep(
            fogStart,
            fogEnd,
            viewDistance
        );

    fogAmount =
        clamp(
            fogAmount,
            0.0,
            0.50
        );

    vec3 finalColor =
        mix(
            sceneColor.rgb,
            fogColor,
            fogAmount
        );

    color =
        vec4(
            finalColor,
            sceneColor.a
        );
}
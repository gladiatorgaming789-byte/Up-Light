#version 460

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

#ifdef DISTANT_HORIZONS
uniform sampler2D dhDepthTex0;
uniform float dhNearPlane;
uniform float dhFarPlane;
#endif

uniform int worldTime;
uniform float near;
uniform float far;

in vec2 texcoord;

/* RENDERTARGETS:0 */
layout(location = 0) out vec4 color;

const float TAU = 6.2831853;

float linearizeDepth(
    float depth,
    float nearPlane,
    float farPlane
) {

    float z =
        depth * 2.0 - 1.0;

    return
        (
            2.0 *
            nearPlane *
            farPlane
        ) /
        (
            farPlane +
            nearPlane -
            z *
            (
                farPlane -
                nearPlane
            )
        );
}

void main() {

    vec4 sceneColor =
        texture(
            colortex0,
            texcoord
        );

    float vanillaDepth =
        texture(
            depthtex0,
            texcoord
        ).r;

    bool hasDepth =
        false;

    float viewDistance =
        0.0;

    if (vanillaDepth < 0.9999) {

        viewDistance =
            linearizeDepth(
                vanillaDepth,
                near,
                far
            );

        hasDepth =
            true;
    }

    #ifdef DISTANT_HORIZONS

    float dhDepth =
        texture(
            dhDepthTex0,
            texcoord
        ).r;

    if (dhDepth < 0.9999) {

        float dhViewDistance =
            linearizeDepth(
                dhDepth,
                dhNearPlane,
                dhFarPlane
            );

        if (
            !hasDepth ||
            dhViewDistance < viewDistance
        ) {

            viewDistance =
                dhViewDistance;

            hasDepth =
                true;
        }
    }

    #endif

    /*
        No vanilla or DH geometry at this pixel.
        Leave sky untouched because skybasic already handles sky atmosphere.
    */
    if (!hasDepth) {

        color =
            sceneColor;

        return;
    }

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
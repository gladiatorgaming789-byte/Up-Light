layout(location = 0) out vec4 outColor0;

const float VOXY_TAU = 6.2831853;

vec2 voxy_normalizeLightmap(
    vec2 lightMap
) {

    vec2 lm =
        lightMap;

    if (
        max(
            lm.x,
            lm.y
        ) > 1.5
    ) {

        lm /=
            256.0;
    }

    return
        clamp(
            lm,
            vec2(0.0),
            vec2(1.0)
        );
}

void voxy_emitFragment(
    VoxyFragmentParameters parameters
) {

    float timeOfDay =
        mod(
            float(worldTime),
            24000.0
        );

    float rawDayFactor =
        sin(
            timeOfDay *
            VOXY_TAU /
            24000.0
        ) * 0.5 + 0.5;

    float dayFactor =
        smoothstep(
            0.12,
            0.88,
            rawDayFactor
        );

    vec2 lightMap =
        voxy_normalizeLightmap(
            parameters.lightMap
        );

    float blockLight =
        lightMap.x;

    float skyLight =
        lightMap.y;

    vec3 baseColor =
        parameters.sampledColour.rgb *
        parameters.tinting.rgb;

    vec3 dayTint =
        vec3(
            1.00,
            0.96,
            0.88
        );

    vec3 nightTint =
        vec3(
            0.30,
            0.36,
            0.56
        );

    vec3 timeTint =
        mix(
            nightTint,
            dayTint,
            dayFactor
        );

    float skyBrightness =
        mix(
            0.46,
            0.92,
            dayFactor
        );

    skyBrightness *=
        mix(
            0.82,
            1.0,
            skyLight
        );

    float blockBrightness =
        blockLight *
        0.45;

    float brightness =
        skyBrightness +
        blockBrightness;

    brightness =
        clamp(
            brightness,
            0.34,
            1.05
        );

    vec3 finalColor =
        baseColor *
        timeTint *
        brightness;

    outColor0 =
        vec4(
            finalColor,
            1.0
        );
}
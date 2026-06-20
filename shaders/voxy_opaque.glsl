layout(location = 0) out vec4 outColor0;

const float VOXY_AMBIENT_LIGHT_STRENGTH = 0.44;
const float VOXY_DIRECT_LIGHT_STRENGTH = 0.45;
const float VOXY_TAU = 6.2831853;

vec3 voxy_getFaceNormal(
    uint face
) {

    uint axis =
        face >> 1u;

    float side =
        (
            (face & 1u) == 1u
        ) ?
        1.0 :
        -1.0;

    vec3 normal =
        vec3(
            axis == 2u ? 1.0 : 0.0,
            axis == 0u ? 1.0 : 0.0,
            axis == 1u ? 1.0 : 0.0
        ) *
        side;

    return
        normalize(
            normal
        );
}

vec3 voxy_getLightmapTint(
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

    lm =
        clamp(
            lm,
            vec2(0.0),
            vec2(1.0)
        );

    float blockLight =
        lm.x;

    float skyLight =
        lm.y;

    vec3 blockLightColor =
        vec3(
            1.00,
            0.72,
            0.42
        ) *
        blockLight;

    vec3 skyLightColor =
        vec3(
            1.0
        ) *
        skyLight;

    vec3 lightColor =
        max(
            skyLightColor,
            blockLightColor
        );

    return
        max(
            lightColor,
            vec3(0.25)
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

    float transitionDistance =
        abs(
            rawDayFactor - 0.5
        ) * 2.0;

    float stableDirectLight =
        smoothstep(
            0.22,
            0.68,
            transitionDistance
        );

    vec3 daylightColor =
        vec3(
            1.00,
            0.93,
            0.80
        );

    vec3 moonlightColor =
        vec3(
            0.26,
            0.34,
            0.62
        );

    vec3 directLightColor =
        mix(
            moonlightColor,
            daylightColor,
            dayFactor
        );

    vec3 normalDirection =
        voxy_getFaceNormal(
            parameters.face
        );

    vec3 sunDirection =
        normalize(
            shadowLightPosition
        );

    float diffuse =
        max(
            dot(
                normalDirection,
                sunDirection
            ),
            0.0
        );

    vec3 baseColor =
        parameters.sampledColour.rgb *
        parameters.tinting.rgb;

    vec3 lighting =
        vec3(
            VOXY_AMBIENT_LIGHT_STRENGTH
        ) +
        directLightColor *
        diffuse *
        VOXY_DIRECT_LIGHT_STRENGTH *
        stableDirectLight;

    vec3 finalColor =
        baseColor *
        voxy_getLightmapTint(
            parameters.lightMap
        ) *
        lighting;

    outColor0 =
        vec4(
            finalColor,
            1.0
        );
}
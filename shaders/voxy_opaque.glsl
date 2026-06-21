layout(location = 0) out vec4 outColor0;

const float VOXY_TAU = 6.2831853;

vec3 voxy_getFaceNormal(
    uint face
) {

    uint axis =
        face >> 1u;

    float side =
        float(
            int(
                face & 1u
            )
        ) * 2.0 - 1.0;

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
                    VOXY_TAU /
                    12000.0
                )
            ),
            2.0
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

    vec3 daylightColor =
        vec3(
            1.00,
            0.93,
            0.80
        );

    vec3 moonlightColor =
        vec3(
            0.34,
            0.44,
            0.76
        );

    vec3 sunsetColor =
        vec3(
            1.00,
            0.42,
            0.18
        );

    vec3 directLightColor =
        mix(
            moonlightColor,
            daylightColor,
            dayFactor
        );

    directLightColor =
        mix(
            directLightColor,
            sunsetColor,
            dawnDuskFactor * 0.16
        );

    vec3 dayAmbientColor =
        vec3(
            1.00,
            0.96,
            0.88
        );

    vec3 nightAmbientColor =
        vec3(
            0.40,
            0.48,
            0.76
        );

    vec3 sunsetAmbientColor =
        vec3(
            1.00,
            0.52,
            0.28
        );

    vec3 ambientColor =
        mix(
            nightAmbientColor,
            dayAmbientColor,
            dayFactor
        );

    ambientColor =
        mix(
            ambientColor,
            sunsetAmbientColor,
            dawnDuskFactor * 0.10
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

    /*
        Voxy LODs do not match vanilla terrain lightmaps exactly.
        This keeps sky-lit LOD terrain readable at night without making it fullbright.
    */
    float skyLightInfluence =
        mix(
            0.58,
            1.0,
            skyLight
        );

    float ambientStrength =
        mix(
            0.50,
            0.66,
            dayFactor
        ) *
        skyLightInfluence;

    vec3 ambientLighting =
        ambientColor *
        ambientStrength;

    directLighting =
        directLightColor *
        diffuse *
        0.24 *
        stableDirectLight *
        mix(
            0.45,
            1.0,
            skyLight
        );

    vec3 blockLighting =
        vec3(
            1.00,
            0.70,
            0.38
        ) *
        pow(
            blockLight,
            1.10
        ) *
        1.10;

    vec3 lighting =
        ambientLighting +
        directLighting +
        blockLighting;

    lighting =
        max(
            lighting,
            vec3(
                0.22,
                0.25,
                0.38
            )
        );

    vec3 nightLift =
        baseColor *
        vec3(
            0.26,
            0.30,
            0.46
        );

    vec3 finalColor =
        baseColor *
        lighting;

    finalColor =
        max(
            finalColor,
            nightLift *
            (
                1.0 - dayFactor
            )
        );

    outColor0 =
        vec4(
            finalColor,
            1.0
        );
}
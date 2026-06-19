#version 460

in vec3 skyDirection;

uniform int worldTime;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

void main() {

    vec3 worldSunDirection =
        normalize(
            mat3(gbufferModelViewInverse) *
            shadowLightPosition
        );

    vec3 dir =
        normalize(
            skyDirection
        );

    float sunAmount =
        max(
            dot(
                dir,
                worldSunDirection
            ),
            0.0
        );

    pow(
        sunAmount,
        4.0
    );

    vec3 atmosphereColor =
        vec3(
            0.70,
            0.85,
            1.00
        );

    float timeOfDay =
        mod(
            float(worldTime),
            24000.0
        );

    float skyTime =
        mod(
            timeOfDay + 1850.0,
            24000.0
        );

    float rawDayFactor =
        sin(
            timeOfDay *
            6.2831853 /
            24000.0
        ) * 0.5 + 0.5;

    float dayFactor =
        smoothstep(
            0.15,
            0.85,
            rawDayFactor
        );
        
    float dawnDuskFactor =
        pow(
            max(
                0.0,
                sin(
                    skyTime *
                    6.2831853 /
                    12000.0
                )
            ),
            2.0
        );

    float t =
        clamp(
            dir.y * 0.5 + 0.5,
            0.0,
            1.0
        );

    float horizonBand =
        1.0 -
        abs(
            t - 0.5
        ) * 1.5;

    horizonBand =
        clamp(
            horizonBand,
            0.0,
            2.0
        );

    horizonBand =
        pow(
            horizonBand,
            3.0
        );

    float horizonGlow =
        horizonBand *
        dawnDuskFactor;

    vec3 sunsetColor =
        vec3(
            1.00,
            0.55,
            0.20
        );

    vec3 dayHorizon =
        vec3(
            0.85,
            0.92,
            1.00
        );

    vec3 dayZenith =
        vec3(
            0.45,
            0.65,
            1.00
        );

    vec3 nightHorizon =
        vec3(
            0.04,
            0.05,
            0.10
        );

    vec3 nightZenith =
        vec3(
            0.01,
            0.02,
            0.06
        );
        
    vec3 horizonColor =
        mix(
            nightHorizon,
            dayHorizon,
            dayFactor
        );

    vec3 zenithColor =
        mix(
            nightZenith,
            dayZenith,
            dayFactor
        );

    vec3 skyColor =
        mix(
            horizonColor,
            zenithColor,
            t
        );

    float upperSkyGlow =
        pow(
            dawnDuskFactor,
            1.5
        ) *
        pow(
            t,
            0.7
        );

    vec3 upperAtmosphereColor =
        vec3(
            1.00,
            0.55,
            0.35
        );

    skyColor =
        mix(
            skyColor,
            upperAtmosphereColor,
            upperSkyGlow * 0.20
        );

    skyColor =
        mix(
            skyColor,
            sunsetColor,
            horizonGlow * 0.3
        );

    float sunHeight =
        clamp(
            worldSunDirection.y * 0.5 + 0.5,
            0.0,
            1.0
        );

    float middayBoost =
        smoothstep(
            0.25,
            0.85,
            sunHeight
        );

    float oppositeAmount =
        max(
            dot(
                dir,
                -worldSunDirection
            ),
            0.0
        );

    float oppositeAtmosphere =
        pow(
            oppositeAmount,
            2.0
        );

    skyColor +=
        vec3(
            0.05,
            0.10,
            0.20
        ) *
        oppositeAtmosphere *
        middayBoost *
        0.25;

    outColor0 =
        vec4(
            skyColor,
            1.0
        );
}
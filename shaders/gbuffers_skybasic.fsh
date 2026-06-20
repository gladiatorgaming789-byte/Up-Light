#version 460

in vec3 skyDirection;

uniform int worldTime;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

const float TAU = 6.2831853;

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

    float celestialAmount =
        max(
            dot(
                dir,
                worldSunDirection
            ),
            0.0
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
            TAU /
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
                    TAU /
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
            1.0
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
            horizonGlow * 0.25
        );

    /*
        Stage 6C: Horizon haze.

        This adds a soft atmospheric band near the horizon.
        It is subtle during the day, cooler at night, and warmer at sunrise/sunset.
    */
    float horizonHaze =
        1.0 -
        smoothstep(
            0.02,
            0.45,
            abs(
                dir.y
            )
        );

    horizonHaze =
        pow(
            clamp(
                horizonHaze,
                0.0,
                1.0
            ),
            1.35
        );

    vec3 dayHazeColor =
        vec3(
            0.78,
            0.88,
            1.00
        );

    vec3 nightHazeColor =
        vec3(
            0.07,
            0.09,
            0.17
        );

    vec3 sunsetHazeColor =
        vec3(
            1.00,
            0.62,
            0.32
        );

    vec3 hazeColor =
        mix(
            nightHazeColor,
            dayHazeColor,
            dayFactor
        );

    hazeColor =
        mix(
            hazeColor,
            sunsetHazeColor,
            dawnDuskFactor * 0.45
        );

    float hazeStrength =
        mix(
            0.10,
            0.18,
            dayFactor
        );

    hazeStrength +=
        dawnDuskFactor *
        0.08;

    skyColor =
        mix(
            skyColor,
            hazeColor,
            horizonHaze * hazeStrength
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

    /*
        Atmospheric scattering.

        The second multiplier prevents the atmosphere from becoming strongest
        directly on top of the sun/moon texture. This keeps the celestial body
        from becoming overexposed while preserving a glow around it.
    */
    float atmosphere =
        pow(
            celestialAmount,
            2.0
        ) *
        (
            1.0 -
            pow(
                celestialAmount,
                8.0
            )
        );

    vec3 atmosphereColor =
        vec3(
            0.70,
            0.85,
            1.00
        );

    skyColor +=
        atmosphereColor *
        atmosphere *
        middayBoost *
        0.15;

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

    /*
        Stage 6B: Sun / Moon halo.

        This is intentionally placed in skybasic so it renders behind the
        actual sun/moon texture from skytextured.
    */
    float haloWide =
        pow(
            celestialAmount,
            5.0
        );

    float haloCore =
        pow(
            celestialAmount,
            18.0
        ) *
        (
            1.0 -
            pow(
                celestialAmount,
                96.0
            )
        );

    vec3 sunHaloColor =
        vec3(
            1.00,
            0.78,
            0.45
        );

    vec3 moonHaloColor =
        vec3(
            0.35,
            0.45,
            0.75
        );

    vec3 haloColor =
        mix(
            moonHaloColor,
            sunHaloColor,
            dayFactor
        );

    float haloStrength =
        mix(
            0.10,
            0.22,
            dayFactor
        );

    skyColor +=
        haloColor *
        (
            haloWide * 0.35 +
            haloCore
        ) *
        haloStrength;

    outColor0 =
        vec4(
            skyColor,
            1.0
        );
}
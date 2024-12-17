// Packing
half3 UnpackNormalAG(half4 packedNormal, half scale)
{
    half3 normal;
    normal.xy = packedNormal.ag * 2.0 - 1.0;
    normal.z = max(1.0e-16, sqrt(1.0 - saturate(dot(normal.xy, normal.xy))));

    normal.xy *= scale;
    return normal;
}

half3 UnpackNormalmapRGorAG(half4 packedNormal, half scale)
{
    packedNormal.a *= packedNormal.r;
    return UnpackNormalAG(packedNormal, scale);
}

// Operations
half3 NormalBlend(half3 A, half3 B)
{
    return normalize(half3(A.rg + B.rg, A.b * B.b));
}

half3 NormalStrength(half3 normal, half strength)
{
    normal.xy *= strength;
    return normalize(normal);
}

half3 SampleNormalMap(sampler2D map, float2 uv)
{
    half4 sampleResult = tex2D(map, uv);
    return UnpackNormalmapRGorAG(sampleResult, 1);
}

half3 TransformNormalToWS(half3 tangent, half3 normal, half3 bitangent, half3 normal_ts)
{
    return normalize(mul(float3x3(tangent, bitangent, normal), normal_ts));
}
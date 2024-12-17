float Fresnel(float3 normal, float3 viewDir, float power)
{
    return pow((1.0 - saturate(dot(normalize(normal), normalize(viewDir)))), power);
}
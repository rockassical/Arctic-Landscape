void VertexFunction(Attributes attribs, out Interpolators varyings)
{
	float4 position_ws = mul(UNITY_MATRIX_M, attribs.position_os);
	float4 position_cs = mul(UNITY_MATRIX_VP, position_ws);
	float4 position_ss = ComputeScreenPos(position_cs);

	varyings.uv_ws = position_ws.xz;
	varyings.position_ss = position_ss;
	varyings.viewVector_ws = _WorldSpaceCameraPos - position_ws.xyz;
	varyings.position_cs = position_cs;
}
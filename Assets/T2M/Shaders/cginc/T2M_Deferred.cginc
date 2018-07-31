#ifndef VACUUM_SHADERS_T2M_DEFERRED_CGINC
#define VACUUM_SHADERS_T2M_DEFERRED_CGINC

#include "../cginc/T2M_Variables.cginc"

struct Input 
{
	float2 uv_V_T2M_Control;
	float3 worldPos;
	fixed3 poweredWorldNormal;

	#ifdef V_T2M_2_CONTROL_MAPS
		float2 uv_V_T2M_Control2;
	#endif
};

	half4 GetTriPlanarBlend( sampler2D tex,half3 worldPos,half3 blending,half tilling) 
	{   
		half4 xUV =tex2D(tex,worldPos.zy *tilling);
		half4 yUV =tex2D(tex,worldPos.xz*tilling);
		half4 zUV =tex2D(tex,worldPos.xy *tilling);
		half4 blendCol =xUV *blending.x + yUV * blending.y +zUV *blending.z;
		return blendCol;
	}

#ifdef V_T2M_STANDARD
void surf (Input IN, inout SurfaceOutputStandard o)
#else
void surf (Input IN, inout SurfaceOutput o) 
#endif
{
	float3 testColor;

	half4 splat_control = tex2D (_V_T2M_Control, IN.uv_V_T2M_Control);

	fixed4 splatColor1 = fixed4(0, 0, 0, 0);
	#if _TRIPLANAR1
	splatColor1 = splat_control.r * GetTriPlanarBlend(_V_T2M_Splat1,IN.worldPos,IN.poweredWorldNormal,_V_T2M_Splat1_uvScale);
	#else
	splatColor1 = splat_control.r * tex2D(_V_T2M_Splat1, IN.uv_V_T2M_Control * _V_T2M_Splat1_uvScale);
	#endif

	fixed4 mainTex = splatColor1;
	fixed4 splatColor2 = splat_control.g * tex2D(_V_T2M_Splat2, IN.uv_V_T2M_Control * _V_T2M_Splat2_uvScale);
	       mainTex += splatColor2;
		   testColor = splat_control.g;
	
	#ifdef V_T2M_3_TEX
		   fixed4 splatColor3 = splat_control.b * tex2D(_V_T2M_Splat3, IN.uv_V_T2M_Control * _V_T2M_Splat3_uvScale);
		mainTex += splatColor3;
	#endif
	#ifdef V_T2M_4_TEX
		fixed4 splatColor4 = splat_control.a * tex2D(_V_T2M_Splat4, IN.uv_V_T2M_Control * _V_T2M_Splat4_uvScale);
		mainTex += splatColor4;
	#endif


	#ifdef V_T2M_2_CONTROL_MAPS
		 half4 splat_control2 = tex2D (_V_T2M_Control2, IN.uv_V_T2M_Control2);

		 fixed4 splatColor5= tex2D(_V_T2M_Splat5, IN.uv_V_T2M_Control2 * _V_T2M_Splat5_uvScale) * splat_control2.r;
		 mainTex.rgb += splatColor5.rgb;

		 #ifdef V_T2M_6_TEX
		 fixed4 splatColor6 = tex2D(_V_T2M_Splat6, IN.uv_V_T2M_Control2 * _V_T2M_Splat6_uvScale) * splat_control2.g;
			mainTex.rgb += splatColor6.rgb;
		 #endif

		 #ifdef V_T2M_7_TEX
			fixed4 splatColor7 = tex2D(_V_T2M_Splat7, IN.uv_V_T2M_Control2 * _V_T2M_Splat7_uvScale) * splat_control2.b;
			mainTex.rgb += splatColor7.rgb;
		 #endif

		 #ifdef V_T2M_8_TEX
			fixed4 splatColor8 = tex2D(_V_T2M_Splat8, IN.uv_V_T2M_Control2 * _V_T2M_Splat8_uvScale) * splat_control2.a;
			mainTex.rgb += splatColor8.rgb;
		 #endif
	#endif



	mainTex.rgb *= _Color.rgb;

	 
	#ifdef V_T2M_BUMP
		fixed4 nrm = 0.0f;
		#if _TRIPLANAR1
		nrm += splat_control.r * GetTriPlanarBlend(_V_T2M_Splat1_bumpMap,IN.worldPos,IN.poweredWorldNormal,_V_T2M_Splat1_uvScale);
		#else
		nrm += splat_control.r * tex2D(_V_T2M_Splat1_bumpMap, IN.uv_V_T2M_Control * _V_T2M_Splat1_uvScale);
		#endif

		nrm += splat_control.g * tex2D(_V_T2M_Splat2_bumpMap, IN.uv_V_T2M_Control * _V_T2M_Splat2_uvScale);

		#ifdef V_T2M_3_TEX
			nrm += splat_control.b * tex2D (_V_T2M_Splat3_bumpMap, IN.uv_V_T2M_Control * _V_T2M_Splat3_uvScale);
		#endif

		#ifdef V_T2M_4_TEX
			nrm += splat_control.a * tex2D (_V_T2M_Splat4_bumpMap, IN.uv_V_T2M_Control * _V_T2M_Splat4_uvScale);
		#endif
		 
		 
		o.Normal = UnpackNormal(nrm);
	#endif


	

	#ifdef V_T2M_STANDARD
		half metallic = 0;
		metallic += splat_control.r * _V_T2M_Splat1_Metallic;
		metallic += splat_control.g * _V_T2M_Splat2_Metallic;
		#ifdef V_T2M_3_TEX
			metallic += splat_control.b * _V_T2M_Splat3_Metallic;
		#endif
		#ifdef V_T2M_4_TEX
			metallic += splat_control.a * _V_T2M_Splat4_Metallic;
		#endif
		#ifdef V_T2M_2_CONTROL_MAPS
			#ifdef V_T2M_5_TEX
				metallic += splat_control2.r * _V_T2M_Splat5_Metallic;
			#endif
			#ifdef V_T2M_6_TEX
				metallic += splat_control2.g * _V_T2M_Splat6_Metallic;
			#endif
			#ifdef V_T2M_7_TEX
				metallic += splat_control2.b * _V_T2M_Splat7_Metallic;
			#endif
			#ifdef V_T2M_8_TEX
				metallic += splat_control2.a * _V_T2M_Splat8_Metallic;
			#endif
		#endif


		half glossiness = 0;
		glossiness += splatColor1.a * _V_T2M_Splat1_Glossiness;
		glossiness += splatColor2.a * _V_T2M_Splat2_Glossiness;
		#ifdef V_T2M_3_TEX
			glossiness += splatColor3.a * _V_T2M_Splat3_Glossiness;
		#endif
		#ifdef V_T2M_4_TEX
			glossiness += splatColor4.a * _V_T2M_Splat4_Glossiness;
		#endif
		#ifdef V_T2M_2_CONTROL_MAPS
			#ifdef V_T2M_5_TEX
				glossiness += splatColor5.a * _V_T2M_Splat5_Glossiness;
			#endif
			#ifdef V_T2M_6_TEX
				glossiness += splatColor6.a * _V_T2M_Splat6_Glossiness;
			#endif
			#ifdef V_T2M_7_TEX
				glossiness += splatColor7.a * _V_T2M_Splat7_Glossiness;
			#endif
			#ifdef V_T2M_8_TEX
				glossiness += splatColor8.a * _V_T2M_Splat8_Glossiness;
			#endif
		#endif

		o.Metallic = metallic;
		o.Smoothness = glossiness;
	#else
		#ifdef V_T2M_SPECULAR
			o.Gloss = mainTex.a;

			half shininess = 0;
			shininess += splat_control.r * _V_T2M_Splat1_Shininess;
			shininess += splat_control.g * _V_T2M_Splat2_Shininess;
			#ifdef V_T2M_3_TEX
				shininess += splat_control.b * _V_T2M_Splat3_Shininess;
			#endif
			#ifdef V_T2M_4_TEX
				shininess += splat_control.a * _V_T2M_Splat4_Shininess;
			#endif

			o.Specular = shininess;
		#endif
	#endif
	

	

	o.Albedo = mainTex.rgb;
	o.Alpha = 1.0;

	//o.Albedo = testColor;
}

#endif
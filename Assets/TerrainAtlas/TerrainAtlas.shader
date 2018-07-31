Shader "TerrainAtlas"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_IndexTex("Index Texture", 2D) = "white" {}
		_BlendTex("Blend Texture", 2D) = "white" {}
		_BlockParams("Block Params",Vector) = (0.0078125, 0.234375, 0.25, 0)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float4 worldPos : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;

			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			sampler2D _IndexTex;
			float4 _IndexTex_ST;
			
			sampler2D _BlendTex;

			float4 _BlockParams;

			float modeFunction(float ori, float modFactor)
			{
				return ori - modFactor * floor(ori / modFactor);
			}

			half4 GetColorByIndex(float index, float lodLevel, float2 worldPos)
			{
				float2 columnAndRow;
				//先取列再取行，范围都是0到3
				columnAndRow.x = (index % 4.0);
				columnAndRow.y = floor((float((index % 16.0))) / 4.0);

				float4 curUV;
				//由于是4x4的图集，所以具体的行列需要乘以0.25 
				//如1就是（0.25, 0），刚好对应第二张贴图的起始位置
				//curUV.xy = ((columnAndRow * 0.25) + ((frac((worldPos * _BlockParams.z)) 
				//	* _BlockParams.yy) + _BlockParams.xx));
				curUV.xy = ((columnAndRow * 0.25) + ((frac((worldPos * _BlockParams.z)) 
					* _BlockParams.yy) + _BlockParams.xx));
				curUV.w = lodLevel;
				return tex2Dlod(_MainTex, curUV);
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.uv, _IndexTex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);

				//记录观察空间的Z值
				o.worldPos.w = mul(UNITY_MATRIX_MV, v.vertex).z;

				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half lodLevel = min(-i.worldPos.w * 0.1, 3);

				//将贴图中被压缩到0,1之间的Index还原
				float indexLayer1 = floor((tex2D (_IndexTex, i.uv.zw).r * 15));
				float indexLayer2 = floor((tex2D (_IndexTex, i.uv.zw).g * 15));
				float indexLayer3 = floor((tex2D (_IndexTex, i.uv.zw).b * 15));

				//利用Index取得具体的贴图位置
				float4 colorLayer1 = GetColorByIndex(indexLayer1, lodLevel, i.worldPos.xz);
				float4 colorLayer2 = GetColorByIndex(indexLayer2, lodLevel, i.worldPos.xz);
				float4 colorLayer3 = GetColorByIndex(indexLayer3, lodLevel, i.worldPos.xz);

				//混合因子，其中r通道为第一层贴图所占权重，g通道为第二层贴图所占权重，b通道为第三层贴图所占权重
				float3 blend = tex2D (_BlendTex, i.uv.xy).rgb;
				half4 albedo = colorLayer1 * blend.r + colorLayer2 * blend.g + colorLayer3 * blend.b;

				//Lambert 光照模型
				float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				half NoL = saturate(dot(normalize(i.worldNormal), lightDir));
				half4 diffuseColor = _LightColor0 * NoL * albedo;
				return diffuseColor;
			}
			ENDCG
		}
	}
}

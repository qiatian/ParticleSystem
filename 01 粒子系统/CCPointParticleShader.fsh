uniform highp mat4 u_mvpMatrix;//MVP变换矩阵
uniform sampler2D u_samplers2D[1];//纹理
uniform highp vec3 u_garvity;//重力--地球重力
uniform highp float u_elapsedSeconds;//当前时间

varying lowp float v_particleOpactity;//粒子透明度 
void main()
{
    //在当前坐标获取纹理值
    lowp vec4 textureColor = texture2D(u_samplers2D[0],gl_PointCoord);
    textureColor.a = textureColor.a * v_particleOpacity;
    gl_FragColor = textureColor;
}

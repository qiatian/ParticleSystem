//Vertex shader
attribute vec3 a_emissonPosition;//位置
attribute vec3 a_emissionVelocity;//速度
attribute vec3 a_emissionForce;//重力==自身重力
attribute vec2 a_size;//大小
attribute vec2 a_emissionAndDeathTimes;

uniform highp mat4 u_mvpMatrix;//MVP变换矩阵
uniform sampler2D u_samplers2D[1];//纹理
uniform highp vec3 u_garvity;//重力--地球重力
uniform highp float u_elapsedSeconds;//当前时间
//varying
varying lowp float v_particleOpactity;//粒子透明度 
void main()
{
    //流逝时间
    highp float elaspedTime = u_elapsedSeconds - a_emissionAndDeathTimes.x;
    //质量：加速度=力 v= v0 + at; 初速度+加速度*时间
    highp vec3 velocity = a_emissioinVelocity + ((a_emissionForce + u_gravity)*elaspedTime);
    //s = s0 + 0.4 *(v0+V)*t 当前位置= 初始位置 + 加速度*（初始速度+当前速度）*时间
    highp vec3 untransformedPosition = a_emissonPosition + 0.5*(a_emissionVelocity+velocity)*elaspedTime;
    
    //得出点的位置
    gl_Position = u_mvpMatrix * vec4(untransformedPosition,1.0);
    gl_PosintSize = a_size.x / gl_Position.w;
    
    //消失时间 亮度 透明度
    v_particleOpactity = max(0.0,min(1.0,(a_emissionAndDeathTimes.y-u_elapsedSeconds)/max(a_size.y,0.00001)));
    
    
    
    
}

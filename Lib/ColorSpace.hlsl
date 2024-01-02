#if !defined(COLOR_SPACE_HLSL)
#define COLOR_SPACE_HLSL

#define WHITEPOINT_X 0.950456
#define WHITEPOINT_Y 1.0
#define WHITEPOINT_Z 1.088754
#define WHITEPOINT float3(WHITEPOINT_X, WHITEPOINT_Y, WHITEPOINT_Z)
#define MIN3(A,B,C) (((A) <= (B)) ? min(A,C) : min(B,C))

#define INVGAMMACORRECTION(t) (((t) <= 0.0404482362771076)? ((t)/12.92) : pow(((t) + 0.055)/1.055, 2.4))
#define GAMMACORRECTION(t) (((t) <= 0.0031306684425005883) ? (12.92*(t)) : (1.055*pow((t), 0.416666666666666667) - 0.055))
#define LABF(t) ((t >= 8.85645167903563082e-3) ? pow(t,0.333333333333333) : (841.0/108.0)*(t) + (4.0/29.0))
#define LABINVF(t) ((t >= 0.206896551724137931) ? ((t)*(t)*(t)) : (108.0/841.0)*((t) - (4.0/29.0)))

#define MIN3(A,B,C) (((A) <= (B)) ? min(A,C) : min(B,C))
#define MAX3(A,B,C) (((A) >= (B)) ? max(A,C) : max(B,C))
#define M_PI    3.14159265358979323846264338327950288
#define Rad2Deg 57.295779
#define Deg2Rad 0.0174533

float3 RgbToXyz(float3 rgb){
    rgb = float3(INVGAMMACORRECTION(rgb.x),INVGAMMACORRECTION(rgb.y),INVGAMMACORRECTION(rgb.z));
    static float3x3 XYZ = float3x3(
        0.4123955889674142161,0.3575834307637148171,0.1804926473817015735,
        0.2125862307855955516,0.7151703037034108499,0.07220049864333622685,
        0.01929721549174694484,0.1191838645808485318,0.9504971251315797660
    );
    
    return mul(XYZ,rgb);
}

float3 XyzToRgb(float3 xyz){
    static float3x3 RGB = float3x3(
        3.2406, -1.5372, -0.4986,
        -0.9689, 1.8758, 0.0415,
        0.0557, -0.2040, 1.0570
    );
    xyz = mul(RGB,xyz);

    float m = MIN3(xyz.x,xyz.y,xyz.z);
    xyz -= m*(m<0);
    xyz = float3(GAMMACORRECTION(xyz.x),GAMMACORRECTION(xyz.y),GAMMACORRECTION(xyz.z));
    return saturate(xyz);
}

float3 XyzToLab(float3 xyz){
    xyz /= WHITEPOINT;
    xyz = float3(LABF(xyz.x),LABF(xyz.y),LABF(xyz.z));
    return float3(116*xyz.y-16,500*(xyz.x-xyz.y),200*(xyz.y - xyz.z));
}
float3 LabToXyz(float3 lab){
    float l = (lab.x+16)/116;
    float a = l + lab.y/500;
    float b = l - lab.z/200;
    return float3(LABINVF(a),LABINVF(l),LABINVF(b)) * WHITEPOINT;
}

float3 XyzToLch(float3 xyz){
    float3 lab = XyzToLab(xyz);
    float c = sqrt(dot(lab.yz,lab.yz));
    float h = atan2(lab.z,lab.y)* Rad2Deg;
    h += 360*(h<0);
    return float3(lab.x,c,h);
}

float3 LchToXyz(float3 lch){
    float a = lch.y * cos(lch.z * Deg2Rad);
    float b = lch.y * sin(lch.z * Deg2Rad);
    return LabToXyz(float3(lch.x,a,b));
}

float3 RgbToLch(float3 rgb){
    return XyzToLch(RgbToXyz(rgb));
}

float3 LchToRgb(float3 lch){
    return XyzToRgb(LchToXyz(lch));
}

#endif //COLOR_SPACE_HLSL
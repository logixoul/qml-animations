pragma Singleton
import QtQuick 2.0

QtObject {
    readonly property string pi: "
        #define PI 3.1415926535897932384626433832795
        "

    // http://stackoverflow.com/a/26070411
    readonly property string atan2:
        pi +
        "
        float atan2(float y, float x)
        {
            bool s = abs(x) > abs(y);
            return s ? atan(y, x) : PI/2.0 - atan(x, y);
        }
        "
    readonly property string premultipliedAlpha: "
        highp vec4 toNonPremultipliedAlpha(highp vec4 inColor) {
            highp vec4 outColor = inColor;
            outColor.rgb /= outColor.a;
            return outColor;
        }

        highp vec4 toPremultipliedAlpha(highp vec4 inColor) {
            highp vec4 outColor = inColor;
            outColor.rgb *= outColor.a;
            return outColor;
        }
        "
    
    // integer abs. Because abs doesn't support ints in our old GLSL version
    readonly property string iabs: "
        int iabs(int i) {
            if(i >= 0)
                return i;
            else
                return -i;
        }
    "
}

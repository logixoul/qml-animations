import QtQuick 2.0
import "utils/"
import "utils/MathUtils.js" as MathUtils

// GaussianBlurBetter is close to a drop-in replacement for Qt Quick's built-in
// GaussianBlur.
// Rationale for its existence:
//      1. Unlike the built-in one, ours doesn't slow down drastically during animation of the `radius` property.
//      2. Ours doesn't have this bug: http://stackoverflow.com/q/42120895
Item {
    id: root
    
    property var source
    // `samples` must be odd
    property int samples: 9 // same default as in Qt's GaussianBlur
     // same default as in Qt's GaussianBlur
    property int radius: Math.floor(samples / 2.0)
    
    property bool cached: true
    
    onSamplesChanged: {
        if(samples % 2 == 0) {
            throw new Error("`samples` must be odd (implementation limitation)");
        }
    }
    
    // shader used both for the *H*orizonatal pass and for the *V*ertical pass
    property string hvFragmentShader:
        GlslUtils.iabs +
        "
        uniform sampler2D uTex;
        uniform int uHalfNumSamples;
        uniform highp vec2 uStep;
        varying highp vec2 qt_TexCoord0;
        void main() {
            %1
            highp vec4 accumulated = vec4(0.0);
            
            for(int i = -uHalfNumSamples; i <= uHalfNumSamples; i++) {
                highp vec4 texel = texture2D(uTex, qt_TexCoord0 + uStep * float(i));
                // in this summation we assume premultiplied alpha
                accumulated += weights[iabs(i)] * texel;
            }
            gl_FragColor = accumulated;
        }
        ".arg(gaussianWeightsString)
    
    // x and stdDev should be floats
    // stdDev means standard deviation
    // see https://en.wikipedia.org/wiki/Gaussian_function
    function calcGaussianFunction(x, stdDev) {
        return Math.exp(-x*x/(2*stdDev*stdDev));
    }
    
    // the created string depends only on root.samples
    property string gaussianWeightsString: {
       var result = "";
       
       // root.samples must be odd
       var numWeights = Math.ceil(root.samples / 2);

       result += "highp float weights[" + numWeights + "];\n";
       
       var weights = new Array(numWeights);
       var weightsSum = 0;
       for(var i = 0; i < weights.length; i++) {
           // the .7 was chosen empirically
           weights[i] = calcGaussianFunction(i / weights.length, .7);
           weightsSum += weights[i];
           if(i != 0) // account for symmetry around 0 by adding twice
               weightsSum += weights[i];
       }
       weights = weights.map(function(w) { return w / weightsSum; });
       for(var i = 0; i < weights.length; i++) {
           result += "weights[" + i + "] = " + weights[i] + ";\n";
       }
       //console.log("GENERATED GLSL CODE:");
       //console.log(result);
       return result;
    }
    
    function getStep(stepDir, texSize) {
        var diameter = root.radius * 2 + 1;
        var result = MathUtils.divideVec2ds(stepDir, texSize).times(diameter / root.samples);
        //console.log("returning step " + result);
        return result;
    }
    
    ShaderEffectSource {
        id: primarySourceTexture
        sourceItem: root.source
        smooth: true
        anchors.fill: parent
        visible: false
    }
    
    ShaderEffect {
        layer.enabled: true
        layer.smooth: true
        id: horzBlurrer // horizontal blurrer
        visible: false
        anchors.fill: parent

        property vector2d texSize: Qt.vector2d(uTex.width, uTex.height)
         // step direction (normalized vector)
        readonly property vector2d stepDir: Qt.vector2d(1, 0)

        // === uniforms ===
        // root.samples must be odd
        property int uHalfNumSamples: Math.floor(root.samples / 2)
        property var uTex: primarySourceTexture
        property vector2d uStep: getStep(stepDir, texSize);
        
        fragmentShader: hvFragmentShader
    }
    
    ShaderEffect {
        id: vertBlurrer // vertical blurrer
        anchors.fill: parent
        property vector2d texSize: Qt.vector2d(uTex.width, uTex.height)
         // step direction (normalized vector)
        readonly property vector2d stepDir: Qt.vector2d(0, 1)

        // === uniforms ===
        // root.samples must be odd
        property int uHalfNumSamples: Math.floor(root.samples / 2)
        property var uTex: horzBlurrer
        property vector2d uStep: getStep(stepDir, texSize);
        
        fragmentShader: hvFragmentShader
    }
    
    // this item is what makes the `cached` property work. I learned this
    // trick from Qt's GaussianBlur implementation
    ShaderEffectSource {
        id: cacheItem
        anchors.fill: vertBlurrer
        visible: root.cached
        smooth: true
        sourceItem: vertBlurrer
        hideSource: visible
    }
}

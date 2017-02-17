import QtQuick 2.0
import QtGraphicalEffects 1.0

// DropShadowBetter is close to a drop-in replacement for Qt Quick's built-in
// DropShadow.
// Rationale for its existence:
//      DropShadow has in its pixel contents also its source, pasted on top of
//      the actual, blurred shadow. So when you use DropShadow, you're normally
//      supposed to make your source item invisible (otherwise it would be drawn twice).
//      But during it's processing, DropShadow distorts its "pasted" source a bit -
//      basically makes it slightly blurry and trembling during an animation of the
//      DropShadow radius. This class remedies that by drawing *only* the actual
//      shadow, thus letting you set the source item to visible so it draws itself.
//      And when it draws itself, it does so without trembling and other artifacts,
//      because it's not passing through any custom processing before being drawn.
Item {
    id: root

    property var source
    property alias samples: blurrer.samples
    property alias radius: blurrer.radius
    property real verticalOffset: 0
    property alias color: shadowTinter.tintColor

    ShaderEffectSource {
        id: primarySourceTexture
        sourceItem: root.source
        smooth: true
    }
    
    // This effect is responsible for:
    //      - replacing the rgb values of the source with the rgb value of the
    //        root.color property
    //      - modulating the alpha values of the source with the alpha value
    //        of the root.color property
    ShaderEffect {
        visible: false
        id: shadowTinter
        property var srcTex: primarySourceTexture
        property color tintColor: Qt.rgba(0, 0, 0, .3)
        width: root.width
        height: root.height

        fragmentShader: "
            uniform sampler2D srcTex;
            uniform highp vec4 tintColor;
            varying highp vec2 qt_TexCoord0;
            void main() {
                highp vec4 c = texture2D(srcTex, qt_TexCoord0);
                gl_FragColor = vec4(tintColor.rgb, c.a * tintColor.a);
            }
            "
    }

    GaussianBlurBetter {
        id: blurrer
        source: shadowTinter

        anchors.fill: root

        // this increases the performance of non-animated items. See my question here:
        // http://stackoverflow.com/q/40028350
        cached: true

        transform: Translate { y: root.verticalOffset }
    }
}

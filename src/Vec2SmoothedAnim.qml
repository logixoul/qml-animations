import QtQuick 2.0

// I first tried doing motion-smoothing with the Qt Quick SmoothedAnimation component
// (see `oldCode/SmoothedAnimation approach for swivelling.txt` for the code),
// but with it the movement was jerky for some reason, so I wrote my own code to do it.
//
// To be clear, this type does the same as Qt Quick's SmoothedAnimation
// component, except that the movement is not jerky, and that it only
// supports `vector2d`-typed properties to animate.
QtObject {
    // to be set from outside to an object whose properties will be animated.
    // Analogous to Qt Quick's `PropertyAnimation.target` property.
    property var target
    // to be set from outside to the name of a property of type `vector2d` to animate.
    // Analogous to Qt Quick's `PropertyAnimation.property` property.
    property string property
    // to be set from outside to a vector2d value toward which we should smoothly move.
    // Analogous to Qt Quick's `PropertyAnimation.to` property.
    property vector2d targetState: Qt.vector2d(0, 0) // private
    
    // returns the `vec` argument with a changed length (changed to `newLength`)
    function withLength(vec, newLength) { // private static
        // can't give a length to a zero vector. Which direction would it point to?
        if(vec.length() === 0.0) {
            if(newLength === 0.0)
                return vec; // return the zero vector
            else
                return null;
        }
        return vec.normalized().times(newLength);
    }
    
    property real decelerationCoef: .8 // const
    
    Timer {
        running: true
        repeat: true
        
        // According to http://doc.qt.io/qt-5/qml-qtqml-timer.html :
        // "The Timer type is synchronized with the animation timer. Since the
        // animation timer is usually set to 60fps, the resolution of Timer
        // will be at best 16ms."
        // So we set it the interval to 1 to get as-fast-as-possible updating
        // of the animation.
        interval: 1
        
        // every time this is called, we move `target[property]` a bit toward `targetState`
        onTriggered: {
            // for an explanation of this algorithm, see `documentation/quadratic_motion_smoothing.txt`
            var state = target[property];
            var delta = targetState.minus(state);
            if(delta.length() === 0.0)
                return;
            var curX = Math.pow(delta.length(), 1.0/2.0);
            curX -= decelerationCoef;
            curX = Math.max(0.0, curX);
            var deltaLenToRemain = Math.pow(curX, 2.0/1.0);
            var toAddLen = delta.length() - deltaLenToRemain;
            var toAdd = withLength(delta, toAddLen);
            
            var newState = state.plus(toAdd);
            
            target[property] = newState;
        }
    }
}

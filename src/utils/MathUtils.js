.pragma library

// https://en.wikipedia.org/wiki/Linear_interpolation
// all arguments should be of type `float`
function lerpFloat(v0, v1, t) {
  return v0 + t*(v1-v0);
}

// both arguments should be of type `vector2d`
function divideVec2ds(a, b) {
    return Qt.vector2d(a.x / b.x, a.y / b.y);
}

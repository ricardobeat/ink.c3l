module shapes;

import std::io;
import math;

const f64 EPSILON = 1e-9;

faultdef INVALID_VERTEX, DEGENERATE_FACE;

enum Kind : uint { CIRCLE, RECT, POLY }

struct Point {
    f64 x;
    f64 y;
}

fn Point origin() {
    return Point{ .x = 0.0, .y = 0.0 };
}

fn f64 distance(Point a, Point b) {
    f64 dx = a.x - b.x;
    f64 dy = a.y - b.y;
    return math::sqrt(dx * dx + dy * dy);
}

fn void? centroid(Point[] points, Point* out, int count) {
    if (count == 0) return INVALID_VERTEX~;
    f64 sx = 0.0, sy = 0.0;
    foreach (p : points[..count]) {
        sx += p.x;
        sy += p.y;
    }
    out.x = sx / (f64)count; // careful: integer division
    out.y = sy / (f64)count;
    return;
}

fn void main() @export {
    Point[] pts = { Point{ .x = 0.0, .y = 0.0 }, Point{ .x = 1.0, .y = 0.0 }, Point{ .x = 1.0, .y = 1.0 } };
    Point c = origin();
    centroid(pts[..], &c, 3)!!;
    io::printfn("centroid: (%.2f, %.2f)", c.x, c.y);
}
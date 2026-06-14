module ink::colour;

typedef Colour = uint;  // 0x00RRGGBB-style (unset = 0)

fn Colour colour_new(char r, char g, char b) @public {
    return (Colour)(((uint)r << 16) | ((uint)g << 8) | (uint)b);
}

fn char hex_digit_to_val(char c) {
    if (c >= '0' && c <= '9') return (char)(c - '0');
    if (c >= 'a' && c <= 'f') return (char)(c - 'a' + 10);
    if (c >= 'A' && c <= 'F') return (char)(c - 'A' + 10);
    return 0xFF;  // sentinel for invalid
}

fn Colour colour_parse(String s) @public {
    if (s.len == 0) return (Colour)0;

    int i = 0;
    if (s.ptr[0] == '#') {
        i = 1;
    }

    int remaining = s.len - i;
    if (remaining == 3) {
        // #rgb → expand each nibble
        char r = hex_digit_to_val(s.ptr[i]);
        char g = hex_digit_to_val(s.ptr[i + 1]);
        char b = hex_digit_to_val(s.ptr[i + 2]);
        if (r == 0xFF || g == 0xFF || b == 0xFF) return (Colour)0;
        return colour_new((char)(r * 0x11), (char)(g * 0x11), (char)(b * 0x11));
    } else if (remaining == 6) {
        // #rrggbb → direct parse
        char r1 = hex_digit_to_val(s.ptr[i]);
        char r2 = hex_digit_to_val(s.ptr[i + 1]);
        char g1 = hex_digit_to_val(s.ptr[i + 2]);
        char g2 = hex_digit_to_val(s.ptr[i + 3]);
        char b1 = hex_digit_to_val(s.ptr[i + 4]);
        char b2 = hex_digit_to_val(s.ptr[i + 5]);
        if (r1 == 0xFF || r2 == 0xFF || g1 == 0xFF || g2 == 0xFF ||
            b1 == 0xFF || b2 == 0xFF) return (Colour)0;
        return colour_new(
            (char)((r1 << 4) | r2),
            (char)((g1 << 4) | g2),
            (char)((b1 << 4) | b2)
        );
    }

    return (Colour)0;
}

fn bool colour_is_set(Colour c) @public {
    return c != (Colour)0;
}

fn char colour_red(Colour c) @public {
    return (char)((c >> 16) & 0xFF);
}

fn char colour_green(Colour c) @public {
    return (char)((c >> 8) & 0xFF);
}

fn char colour_blue(Colour c) @public {
    return (char)(c & 0xFF);
}

fn double colour_brightness(Colour c) @public {
    double r = (double)colour_red(c);
    double g = (double)colour_green(c);
    double b = (double)colour_blue(c);
    return (r * 0.299 + g * 0.587 + b * 0.114) / 255.0;
}

fn char clamp_char(double v) {
    if (v < 0.0) return 0;
    if (v > 255.0) return 255;
    return (char)v;
}

fn Colour colour_brighten(Colour c, double factor) @public {
    double factor_adj = 1.0 + factor;
    double r = (double)colour_red(c) * factor_adj;
    double g = (double)colour_green(c) * factor_adj;
    double b = (double)colour_blue(c) * factor_adj;
    return colour_new(clamp_char(r), clamp_char(g), clamp_char(b));
}

fn Colour colour_clamp_brightness(Colour c, double min, double max) @public {
    double b = colour_brightness(c);
    if (b < min) {
        if (b <= 0.0) {
            // Cannot brighten a fully black color; return a grey at min brightness
            char val = clamp_char(min * 255.0);
            return colour_new(val, val, val);
        }
        double factor = (min / b) - 1.0;
        return colour_brighten(c, factor);
    } else if (b > max) {
        double factor = (max / b) - 1.0;
        return colour_brighten(c, factor);
    }
    return c;
}

fn double mysqrt(double x) {
    if (x <= 0.0) return 0.0;
    double guess = x / 2.0;
    for (int i = 0; i < 20; i++) {
        guess = (guess + x / guess) / 2.0;
    }
    return guess;
}

fn double colour_distance(Colour a, Colour b) @public {
    double dr = (double)colour_red(a) - (double)colour_red(b);
    double dg = (double)colour_green(a) - (double)colour_green(b);
    double db = (double)colour_blue(a) - (double)colour_blue(b);
    return mysqrt(dr * dr + dg * dg + db * db);
}

fn char hex_char(int v) {
    if (v < 10) return (char)('0' + v);
    return (char)('a' + v - 10);
}

fn String colour_string(Colour c) @public {
    char* result = mem::new_array(char, 8);
    result[0] = '#';
    result[1] = hex_char((int)((c >> 20) & 0xF));
    result[2] = hex_char((int)((c >> 16) & 0xF));
    result[3] = hex_char((int)((c >> 12) & 0xF));
    result[4] = hex_char((int)((c >> 8) & 0xF));
    result[5] = hex_char((int)((c >> 4) & 0xF));
    result[6] = hex_char((int)(c & 0xF));
    result[7] = 0;
    return (String)result[0:7];
}

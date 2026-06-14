module ink::test;

import ink::colour;

fn void test_colour_new() @test {
	Colour c = colour::colour_new(0xFF, 0x80, 0x00);
	assert(colour::colour_red(c) == 0xFF);
	assert(colour::colour_green(c) == 0x80);
	assert(colour::colour_blue(c) == 0x00);
}

fn void test_colour_parse_hex6() @test {
	Colour c = colour::colour_parse("#ff8000");
	assert(colour::colour_red(c) == 0xFF);
	assert(colour::colour_green(c) == 0x80);
	assert(colour::colour_blue(c) == 0x00);
}

fn void test_colour_parse_hex3() @test {
	Colour c = colour::colour_parse("#f80");
	assert(colour::colour_red(c) == 0xFF);
	assert(colour::colour_green(c) == 0x88);
	assert(colour::colour_blue(c) == 0x00);
}

fn void test_colour_parse_no_hash() @test {
	Colour c = colour::colour_parse("ff8000");
	assert(colour::colour_red(c) == 0xFF);
	assert(colour::colour_green(c) == 0x80);
	assert(colour::colour_blue(c) == 0x00);
}

fn void test_colour_parse_invalid() @test {
	Colour c = colour::colour_parse("#xyz");
	assert(!colour::colour_is_set(c));
	c = colour::colour_parse("");
	assert(!colour::colour_is_set(c));
}

fn void test_colour_is_set() @test {
	assert(!colour::colour_is_set((Colour)0));
	assert(colour::colour_is_set(colour::colour_new(1, 1, 1)));
}

fn void test_colour_brightness() @test {
	double white_bright = colour::colour_brightness(colour::colour_new(255, 255, 255));
	assert(white_bright > 0.99);
	double black_bright = colour::colour_brightness(colour::colour_new(0, 0, 0));
	assert(black_bright < 0.01);
}

fn void test_colour_distance() @test {
	Colour a = colour::colour_new(100, 100, 100);
	double d = colour::colour_distance(a, a);
	assert(d < 0.01);

	Colour black = colour::colour_new(0, 0, 0);
	Colour white = colour::colour_new(255, 255, 255);
	double d2 = colour::colour_distance(black, white);
	assert(d2 > 400.0);
}

fn void test_colour_string() @test {
	Colour c = colour::colour_new(0xFF, 0x80, 0x00);
	String s = colour::colour_string(c);
	assert(s == "#ff8000");
	// Free the heap-allocated string to avoid leak detection
	s.free(mem);
}

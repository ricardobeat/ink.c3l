package main

import "fmt"

// Fibonacci returns the nth Fibonacci number.
func Fibonacci(n int) int {
	if n <= 1 {
		return n
	}
	a, b := 0, 1
	for i := 2; i <= n; i++ {
		a, b = b, a+b
	}
	return b
}

func main() {
	/* Print the first 10 Fibonacci numbers */
	for i := 0; i < 10; i++ {
		fmt.Printf("F(%d) = %d\n", i, Fibonacci(i))
	}

	msg := "Hello, 世界"
	fmt.Println(msg)
}

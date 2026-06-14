use std::collections::HashMap;

/// A simple key-value store with reference counting.
struct Store {
    data: HashMap<String, Vec<u8>>,
}

impl Store {
    fn new() -> Self {
        Store {
            data: HashMap::new(),
        }
    }

    fn insert(&mut self, key: &str, value: &[u8]) {
        self.data.insert(key.to_string(), value.to_vec());
    }

    fn get(&self, key: &str) -> Option<&Vec<u8>> {
        self.data.get(key)
    }
}

fn main() {
    let mut store = Store::new();

    // Insert some values
    store.insert("name", b"ink");
    store.insert("version", b"0.1.0");

    // Retrieve and print
    match store.get("name") {
        Some(val) => println!("name = {:?}", String::from_utf8_lossy(val)),
        None => println!("not found"),
    }

    let numbers: Vec<i32> = (0..10).map(|x| x * x).collect();
    let sum: i32 = numbers.iter().sum();
    println!("sum of squares = {}", sum);

    let greeting = format!("Hello, {}!", "world");
    println!("{}", greeting);
}

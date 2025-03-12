// Example code that deserializes and serializes the model.
// extern crate serde;
// #[macro_use]
// extern crate serde_derive;
// extern crate serde_json;
//
// use generated_module::Test;
//
// fn main() {
//     let json = r#"{"answer": 42}"#;
//     let model: Test = serde_json::from_str(&json).unwrap();
// }

use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize)]
pub struct Test {
    asdf: String,

    asdf2: String,
}

#[derive(Serialize, Deserialize)]
pub struct Convert {
}

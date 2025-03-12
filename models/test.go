// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse and unparse this JSON data, add this code to your project and do:
//
//    test, err := UnmarshalTest(bytes)
//    bytes, err = test.Marshal()
//
//    convert, err := UnmarshalConvert(bytes)
//    bytes, err = convert.Marshal()

package main

import "encoding/json"

func UnmarshalTest(data []byte) (Test, error) {
	var r Test
	err := json.Unmarshal(data, &r)
	return r, err
}

func (r *Test) Marshal() ([]byte, error) {
	return json.Marshal(r)
}

func UnmarshalConvert(data []byte) (Convert, error) {
	var r Convert
	err := json.Unmarshal(data, &r)
	return r, err
}

func (r *Convert) Marshal() ([]byte, error) {
	return json.Marshal(r)
}

type Test struct {
	Asdf  string `json:"asdf"`
	Asdf2 string `json:"asdf2"`
}

type Convert struct {
}

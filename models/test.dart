// To parse this JSON data, do
//
//     final test = testFromJson(jsonString);
//     final convert = convertFromJson(jsonString);

import 'dart:convert';

Test testFromJson(String str) => Test.fromJson(json.decode(str));

String testToJson(Test data) => json.encode(data.toJson());

Convert convertFromJson(String str) => Convert.fromJson(json.decode(str));

String convertToJson(Convert data) => json.encode(data.toJson());

class Test {
    String asdf;
    String asdf2;

    Test({
        required this.asdf,
        required this.asdf2,
    });

    factory Test.fromJson(Map<String, dynamic> json) => Test(
        asdf: json["asdf"],
        asdf2: json["asdf2"],
    );

    Map<String, dynamic> toJson() => {
        "asdf": asdf,
        "asdf2": asdf2,
    };
}

class Convert {
    Convert();

    factory Convert.fromJson(Map<String, dynamic> json) => Convert(
    );

    Map<String, dynamic> toJson() => {
    };
}

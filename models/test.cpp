//  To parse this JSON data, first install
//
//      Boost     http://www.boost.org
//      json.hpp  https://github.com/nlohmann/json
//
//  Then include this file, and then do
//
//     Test data = nlohmann::json::parse(jsonString);
//     Convert data = nlohmann::json::parse(jsonString);

#pragma once

#include "json.hpp"

#include <boost/optional.hpp>
#include <stdexcept>
#include <regex>

namespace quicktype {
    using nlohmann::json;

    #ifndef NLOHMANN_UNTYPED_quicktype_HELPER
    #define NLOHMANN_UNTYPED_quicktype_HELPER
    inline json get_untyped(const json & j, const char * property) {
        if (j.find(property) != j.end()) {
            return j.at(property).get<json>();
        }
        return json();
    }

    inline json get_untyped(const json & j, std::string property) {
        return get_untyped(j, property.data());
    }
    #endif

    class Test {
        public:
        Test() = default;
        virtual ~Test() = default;

        private:
        std::string asdf;
        std::string asdf2;

        public:
        const std::string & get_asdf() const { return asdf; }
        std::string & get_mutable_asdf() { return asdf; }
        void set_asdf(const std::string & value) { this->asdf = value; }

        const std::string & get_asdf2() const { return asdf2; }
        std::string & get_mutable_asdf2() { return asdf2; }
        void set_asdf2(const std::string & value) { this->asdf2 = value; }
    };

    class Convert {
        public:
        Convert() = default;
        virtual ~Convert() = default;

        private:

        public:
    };
}

namespace quicktype {
    void from_json(const json & j, Test & x);
    void to_json(json & j, const Test & x);

    void from_json(const json & j, Convert & x);
    void to_json(json & j, const Convert & x);

    inline void from_json(const json & j, Test& x) {
        x.set_asdf(j.at("asdf").get<std::string>());
        x.set_asdf2(j.at("asdf2").get<std::string>());
    }

    inline void to_json(json & j, const Test & x) {
        j = json::object();
        j["asdf"] = x.get_asdf();
        j["asdf2"] = x.get_asdf2();
    }

    inline void from_json(const json & j, Convert& x) {
    }

    inline void to_json(json & j, const Convert & x) {
        j = json::object();
    }
}

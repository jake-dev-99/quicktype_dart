// To parse the JSON, install Klaxon and do:
//
//   val testBridge = TestBridge.fromJson(jsonString)

package quicktype

import com.beust.klaxon.*

private val klaxon = Klaxon()

data class TestBridge (
    val asdf: String,
    val asdf2: String
) {
    public fun toJson() = klaxon.toJsonString(this)

    companion object {
        public fun fromJson(json: String) = klaxon.parse<TestBridge>(json)
    }
}

package io.quicktype;

import com.fasterxml.jackson.annotation.*;

public class Test {
    private String asdf;
    private String asdf2;

    @JsonProperty("asdf")
    public String getAsdf() { return asdf; }
    @JsonProperty("asdf")
    public void setAsdf(String value) { this.asdf = value; }

    @JsonProperty("asdf2")
    public String getAsdf2() { return asdf2; }
    @JsonProperty("asdf2")
    public void setAsdf2(String value) { this.asdf2 = value; }
}

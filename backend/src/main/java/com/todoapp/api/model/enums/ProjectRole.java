package com.todoapp.api.model.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum ProjectRole {
    OWNER("owner"),
    ADMIN("admin"),
    MEMBER("member"),
    VIEWER("viewer");

    private final String value;

    ProjectRole(String value) {
        this.value = value;
    }

    @JsonValue
    public String getValue() {
        return value;
    }

    @JsonCreator
    public static ProjectRole fromValue(String value) {
        if (value == null) return null;
        for (ProjectRole r : values()) {
            if (r.value.equalsIgnoreCase(value) || r.name().equalsIgnoreCase(value)) {
                return r;
            }
        }
        throw new IllegalArgumentException("Unknown ProjectRole: " + value);
    }
}

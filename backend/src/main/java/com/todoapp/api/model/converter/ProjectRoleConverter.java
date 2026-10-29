package com.todoapp.api.model.converter;

import com.todoapp.api.model.enums.ProjectRole;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class ProjectRoleConverter implements AttributeConverter<ProjectRole, String> {
    @Override
    public String convertToDatabaseColumn(ProjectRole attribute) {
        return attribute == null ? null : attribute.getValue();
    }

    @Override
    public ProjectRole convertToEntityAttribute(String dbData) {
        return ProjectRole.fromValue(dbData);
    }
}

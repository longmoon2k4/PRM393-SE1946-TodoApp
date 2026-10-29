package com.todoapp.api.model.converter;

import com.todoapp.api.model.enums.TaskStatus;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class TaskStatusConverter implements AttributeConverter<TaskStatus, String> {
    @Override
    public String convertToDatabaseColumn(TaskStatus attribute) {
        return attribute == null ? null : attribute.getValue();
    }

    @Override
    public TaskStatus convertToEntityAttribute(String dbData) {
        return TaskStatus.fromValue(dbData);
    }
}

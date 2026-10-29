package com.todoapp.api.model.converter;

import com.todoapp.api.model.enums.TaskPriority;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class TaskPriorityConverter implements AttributeConverter<TaskPriority, String> {
    @Override
    public String convertToDatabaseColumn(TaskPriority attribute) {
        return attribute == null ? null : attribute.getValue();
    }

    @Override
    public TaskPriority convertToEntityAttribute(String dbData) {
        return TaskPriority.fromValue(dbData);
    }
}

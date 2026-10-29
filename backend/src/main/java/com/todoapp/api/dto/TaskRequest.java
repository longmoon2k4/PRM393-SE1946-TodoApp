package com.todoapp.api.dto;

import lombok.*;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TaskRequest {
    private String title;
    private String description;
    private String status;
    private String priority;
    private Double orderIndex;
    private LocalDateTime startDate;
    private LocalDateTime deadline;
    private LocalDateTime reminderAt;
    private String assigneeId;
    private String projectId;
    private String categoryId;
    private List<String> tags;
}

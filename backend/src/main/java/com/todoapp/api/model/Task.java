package com.todoapp.api.model;

import com.todoapp.api.model.converter.TaskStatusConverter;
import com.todoapp.api.model.converter.TaskPriorityConverter;
import com.todoapp.api.model.enums.TaskStatus;
import com.todoapp.api.model.enums.TaskPriority;
import jakarta.persistence.*;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.*;
import java.time.LocalDateTime;
import java.util.*;

@Entity
@JsonIgnoreProperties({"hibernateLazyInitializer","handler"})
@Table(name = "tasks")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Task {
    @Id
    private String id;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Convert(converter = TaskStatusConverter.class)
    @Column(name = "status", columnDefinition = "enum('todo','in_progress','done','cancelled')")
    private TaskStatus status;

    @Convert(converter = TaskPriorityConverter.class)
    @Column(name = "priority", columnDefinition = "enum('low','medium','high','urgent')")
    private TaskPriority priority;

    @Column(name = "order_index")
    private Double orderIndex;

    @Column(name = "start_date")
    private LocalDateTime startDate;

    @Column(name = "deadline")
    private LocalDateTime deadline;

    @Column(name = "reminder_at")
    private LocalDateTime reminderAt;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assignee_id")
    private User assignee;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "project_id")
    private Project project;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    @OneToMany(mappedBy = "task", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Subtask> subtasks = new ArrayList<>();

    @OneToMany(mappedBy = "task", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<TaskComment> comments = new ArrayList<>();

    @OneToMany(mappedBy = "task", cascade = CascadeType.ALL, orphanRemoval = true)
    @com.fasterxml.jackson.annotation.JsonIgnore
    private List<ActivityLog> activityLogs = new ArrayList<>();

    @ManyToMany
    @JoinTable(name = "task_tags",
            joinColumns = @JoinColumn(name = "task_id"),
            inverseJoinColumns = @JoinColumn(name = "tag_id"))
    private Set<Tag> tags = new HashSet<>();

    @PrePersist
    public void prePersist() {
        if (id == null) id = UUID.randomUUID().toString();
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (status == null) status = TaskStatus.TODO;
        if (priority == null) priority = TaskPriority.MEDIUM;
        if (orderIndex == null) orderIndex = 0.0;
    }
}

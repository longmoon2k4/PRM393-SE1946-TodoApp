package com.todoapp.api.model;

import com.todoapp.api.model.converter.ProjectRoleConverter;
import com.todoapp.api.model.enums.ProjectRole;
import jakarta.persistence.*;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@JsonIgnoreProperties({"hibernateLazyInitializer","handler"})
@Table(name = "project_members")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProjectMember {
    @EmbeddedId
    private ProjectMemberId id;

    @MapsId("projectId")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "project_id")
    @com.fasterxml.jackson.annotation.JsonIgnore
    private Project project;

    @MapsId("userId")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Convert(converter = ProjectRoleConverter.class)
    @Column(name = "role", columnDefinition = "enum('owner','admin','member','viewer')")
    private ProjectRole role;

    @Column(name = "joined_at")
    private LocalDateTime joinedAt;

    @PrePersist
    public void prePersist() {
        if (role == null) role = ProjectRole.MEMBER;
        if (joinedAt == null) joinedAt = LocalDateTime.now();
    }
}

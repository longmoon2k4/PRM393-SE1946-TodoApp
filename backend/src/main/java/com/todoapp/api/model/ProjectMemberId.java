package com.todoapp.api.model;

import jakarta.persistence.Embeddable;
import jakarta.persistence.Column;
import lombok.*;
import java.io.Serializable;

@Embeddable
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProjectMemberId implements Serializable {
    @Column(name = "project_id")
    private String projectId;

    @Column(name = "user_id")
    private String userId;
}

package com.todoapp.api.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SubtaskRequest {
    private String title;
    private Double orderIndex;
}

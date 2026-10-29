package com.todoapp.api.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CommentRequest {
    private String content;
    private String authorId;
}

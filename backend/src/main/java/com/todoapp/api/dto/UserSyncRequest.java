package com.todoapp.api.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserSyncRequest {
    private String id;
    private String email;
    private String name;
    private String avatarUrl;
}

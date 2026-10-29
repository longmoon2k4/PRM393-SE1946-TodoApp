package com.todoapp.api.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderUpdateRequest {
    private Double newOrderIndex;
}

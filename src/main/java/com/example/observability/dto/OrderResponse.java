package com.example.observability.dto;

import com.example.observability.entity.OrderEntity;

import java.time.OffsetDateTime;

public record OrderResponse(
        Long id,
        String externalId,
        String customerId,
        Long amount,
        String status,
        OffsetDateTime createdAt
) {
    public static OrderResponse from(OrderEntity entity) {
        return new OrderResponse(
                entity.getId(),
                entity.getExternalId(),
                entity.getCustomerId(),
                entity.getAmount(),
                entity.getStatus(),
                entity.getCreatedAt()
        );
    }
}

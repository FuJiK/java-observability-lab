package com.example.observability.dto;

public record CreateOrderRequest(
        String externalId,
        String customerId,
        Long amount
) {
}

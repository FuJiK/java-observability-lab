package com.example.observability.exception;

public class OrderNotFoundException extends RuntimeException {

    public OrderNotFoundException(Long orderId) {
        super("Order not found. orderId=" + orderId);
    }
}

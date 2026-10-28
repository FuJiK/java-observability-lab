package com.example.observability.service;

import com.example.observability.dto.CreateOrderRequest;
import com.example.observability.dto.OrderResponse;
import com.example.observability.entity.OrderEntity;
import com.example.observability.exception.OrderNotFoundException;
import com.example.observability.repository.OrderRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;

@Service
public class OrderService {

    private static final Logger log = LoggerFactory.getLogger(OrderService.class);

    private final OrderRepository orderRepository;

    public OrderService(OrderRepository orderRepository) {
        this.orderRepository = orderRepository;
    }

    @Transactional
    public OrderResponse createOrder(CreateOrderRequest request) {
        log.info(
                "Creating order externalId={} customerId={} amount={}",
                request.externalId(),
                request.customerId(),
                request.amount()
        );

        OrderEntity entity = new OrderEntity(
                request.externalId(),
                request.customerId(),
                request.amount(),
                "CREATED",
                OffsetDateTime.now()
        );

        OrderEntity saved = orderRepository.saveAndFlush(entity);
        log.info("Order created orderId={} externalId={}", saved.getId(), saved.getExternalId());

        return OrderResponse.from(saved);
    }

    @Transactional(readOnly = true)
    public OrderResponse getOrder(Long orderId) {
        log.info("Loading order orderId={}", orderId);

        OrderEntity entity = orderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException(orderId));

        log.info("Order loaded orderId={} status={}", entity.getId(), entity.getStatus());
        return OrderResponse.from(entity);
    }
}

package com.example.observability.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/mock/payment")
public class MockPaymentController {

    private static final Logger log = LoggerFactory.getLogger(MockPaymentController.class);

    @GetMapping
    public String payment(
            @RequestParam(defaultValue = "0") long delayMs,
            @RequestParam(defaultValue = "false") boolean fail
    ) throws InterruptedException {
        log.info("Mock payment called delayMs={} fail={}", delayMs, fail);

        if (delayMs > 0) {
            Thread.sleep(delayMs);
        }

        if (fail) {
            throw new MockPaymentException("Mock payment failed intentionally");
        }

        return "APPROVED";
    }

    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    private static class MockPaymentException extends RuntimeException {
        private MockPaymentException(String message) {
            super(message);
        }
    }
}

package com.example.observability.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/lab")
@Profile("lab")
public class LabController {

    private static final Logger log = LoggerFactory.getLogger(LabController.class);
    private static final List<byte[]> MEMORY_HOLDER = new ArrayList<>();

    private final RestClient restClient;

    public LabController(RestClient restClient) {
        this.restClient = restClient;
    }

    @GetMapping("/exception")
    public String exception() {
        log.info("Intentional exception scenario started");
        throw new IllegalStateException("Intentional lab exception");
    }

    @GetMapping("/payment-timeout")
    public String paymentTimeout(
            @RequestParam(defaultValue = "3000") long delayMs
    ) {
        log.info("Calling mock payment service delayMs={}", delayMs);

        try {
            return restClient
                    .get()
                    .uri("http://localhost:8080/mock/payment?delayMs={delayMs}", delayMs)
                    .retrieve()
                    .body(String.class);
        } catch (ResourceAccessException ex) {
            log.error("Payment API timeout or connection error delayMs={}", delayMs, ex);
            throw ex;
        }
    }

    @GetMapping("/payment-500")
    public String payment500() {
        log.info("Calling mock payment service with fail=true");

        return restClient
                .get()
                .uri("http://localhost:8080/mock/payment?fail=true")
                .retrieve()
                .body(String.class);
    }

    @PostMapping("/memory/allocate")
    public String allocateMemory(
            @RequestParam(defaultValue = "10") int megabytes
    ) {
        if (megabytes < 1 || megabytes > 100) {
            throw new IllegalArgumentException("megabytes must be between 1 and 100");
        }

        byte[] block = new byte[megabytes * 1024 * 1024];
        MEMORY_HOLDER.add(block);

        int totalMegabytes = MEMORY_HOLDER.stream()
                .mapToInt(bytes -> bytes.length)
                .sum() / 1024 / 1024;

        log.warn(
                "Intentional memory allocation megabytes={} retainedBlocks={} retainedMegabytes={}",
                megabytes,
                MEMORY_HOLDER.size(),
                totalMegabytes
        );

        return "Retained blocks=" + MEMORY_HOLDER.size()
                + ", approximately " + totalMegabytes + "MB";
    }

    @PostMapping("/memory/clear")
    public String clearMemory() {
        int blocks = MEMORY_HOLDER.size();
        MEMORY_HOLDER.clear();
        log.info("Cleared intentional memory holder blocks={}", blocks);
        return "Cleared blocks=" + blocks;
    }
}

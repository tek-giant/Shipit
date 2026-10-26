package com.shipit;

import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    @GetMapping
    public List<Map<String, Object>> list() {
        return List.of(Map.of("id", 1, "item", "keyboard", "status", "NEW"));
    }
}

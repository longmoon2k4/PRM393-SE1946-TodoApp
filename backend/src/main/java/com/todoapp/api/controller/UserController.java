package com.todoapp.api.controller;

import com.todoapp.api.dto.UserSyncRequest;
import com.todoapp.api.model.User;
import com.todoapp.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;

    @PostMapping("/sync")
    public User syncUser(@RequestBody UserSyncRequest req) {
        User user = null;
        if (req.getId() != null) {
            user = userRepository.findById(req.getId()).orElse(null);
        }
        if (user == null && req.getEmail() != null) {
            user = userRepository.findByEmail(req.getEmail()).orElse(null);
        }
        if (user == null) {
            user = new User();
            if (req.getId() != null) user.setId(req.getId());
        }
        user.setEmail(req.getEmail());
        user.setName(req.getName());
        user.setAvatarUrl(req.getAvatarUrl());
        return userRepository.save(user);
    }

    @GetMapping("/{id}")
    public User getUser(@PathVariable String id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "User not found"));
    }
}

package com.todoapp.api.controller;

import com.todoapp.api.dto.OrderUpdateRequest;
import com.todoapp.api.model.Subtask;
import com.todoapp.api.repository.SubtaskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/subtasks")
@RequiredArgsConstructor
public class SubtaskController {

    private final SubtaskRepository subtaskRepository;

    @PatchMapping("/{id}/toggle")
    @Transactional
    public Subtask toggle(@PathVariable String id) {
        Subtask s = subtaskRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "Subtask not found"));
        s.setIsCompleted(!Boolean.TRUE.equals(s.getIsCompleted()));
        return subtaskRepository.save(s);
    }

    @PatchMapping("/{id}/order")
    @Transactional
    public Subtask updateOrder(@PathVariable String id, @RequestBody OrderUpdateRequest req) {
        Subtask s = subtaskRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "Subtask not found"));
        s.setOrderIndex(req.getNewOrderIndex());
        return subtaskRepository.save(s);
    }

    @DeleteMapping("/{id}")
    @Transactional
    public ResponseEntity<Void> delete(@PathVariable String id) {
        if (!subtaskRepository.existsById(id)) {
            throw new ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "Subtask not found");
        }
        subtaskRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}

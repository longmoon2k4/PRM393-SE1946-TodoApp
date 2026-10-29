package com.todoapp.api.controller;

import com.todoapp.api.dto.ProjectRequest;
import com.todoapp.api.model.Project;
import com.todoapp.api.repository.ProjectRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/projects")
@RequiredArgsConstructor
public class ProjectController {

    private final ProjectRepository projectRepository;

    @GetMapping
    @Transactional(readOnly = true)
    public List<Project> getAll() {
        return projectRepository.findAll().stream()
                .filter(p -> p.getDeletedAt() == null)
                .collect(Collectors.toList());
    }

    @GetMapping("/{id}")
    @Transactional(readOnly = true)
    public Project getOne(@PathVariable String id) {
        return projectRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "Project not found"));
    }

    @PostMapping
    @Transactional
    public Project create(@RequestBody ProjectRequest req) {
        Project p = new Project();
        p.setName(req.getName());
        p.setDescription(req.getDescription());
        return projectRepository.save(p);
    }

    @PutMapping("/{id}")
    @Transactional
    public Project update(@PathVariable String id, @RequestBody ProjectRequest req) {
        Project p = getOne(id);
        if (req.getName() != null) p.setName(req.getName());
        if (req.getDescription() != null) p.setDescription(req.getDescription());
        return projectRepository.save(p);
    }

    @DeleteMapping("/{id}")
    @Transactional
    public ResponseEntity<Void> delete(@PathVariable String id) {
        Project p = getOne(id);
        p.setDeletedAt(LocalDateTime.now());
        projectRepository.save(p);
        return ResponseEntity.ok().build();
    }
}

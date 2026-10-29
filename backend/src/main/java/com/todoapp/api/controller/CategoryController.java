package com.todoapp.api.controller;

import com.todoapp.api.dto.CategoryRequest;
import com.todoapp.api.model.Category;
import com.todoapp.api.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/v1/categories")
@RequiredArgsConstructor
public class CategoryController {

    private final CategoryRepository categoryRepository;

    @GetMapping
    @Transactional(readOnly = true)
    public List<Category> getAll() {
        return categoryRepository.findAll();
    }

    @PostMapping
    @Transactional
    public Category create(@RequestBody CategoryRequest req) {
        Category c = new Category();
        c.setName(req.getName());
        c.setColorHex(req.getColorHex());
        return categoryRepository.save(c);
    }

    @DeleteMapping("/{id}")
    @Transactional
    public ResponseEntity<Void> delete(@PathVariable String id) {
        if (!categoryRepository.existsById(id)) {
            throw new ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "Category not found");
        }
        categoryRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}

package com.todoapp.api.controller;

import com.todoapp.api.dto.CommentRequest;
import com.todoapp.api.dto.OrderUpdateRequest;
import com.todoapp.api.dto.StatusUpdateRequest;
import com.todoapp.api.dto.SubtaskRequest;
import com.todoapp.api.dto.TaskRequest;
import com.todoapp.api.model.*;
import com.todoapp.api.model.enums.TaskPriority;
import com.todoapp.api.model.enums.TaskStatus;
import com.todoapp.api.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/tasks")
@RequiredArgsConstructor
public class TaskController {

    private final TaskRepository taskRepository;
    private final UserRepository userRepository;
    private final ProjectRepository projectRepository;
    private final CategoryRepository categoryRepository;
    private final SubtaskRepository subtaskRepository;
    private final TaskCommentRepository taskCommentRepository;
    private final ActivityLogRepository activityLogRepository;
    private final TagRepository tagRepository;

    @GetMapping
    @Transactional(readOnly = true)
    public List<Task> getAllTasks(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String priority,
            @RequestParam(required = false) String projectId,
            @RequestParam(required = false) String categoryId,
            @RequestParam(required = false) String assigneeId,
            @RequestParam(required = false) String search) {

        TaskStatus st = status != null ? TaskStatus.fromValue(status) : null;
        TaskPriority pr = priority != null ? TaskPriority.fromValue(priority) : null;

        return taskRepository.findAll().stream()
                .filter(t -> t.getDeletedAt() == null)
                .filter(t -> st == null || t.getStatus() == st)
                .filter(t -> pr == null || t.getPriority() == pr)
                .filter(t -> projectId == null || (t.getProject() != null && projectId.equals(t.getProject().getId())))
                .filter(t -> categoryId == null || (t.getCategory() != null && categoryId.equals(t.getCategory().getId())))
                .filter(t -> assigneeId == null || (t.getAssignee() != null && assigneeId.equals(t.getAssignee().getId())))
                .filter(t -> search == null || (t.getTitle() != null && t.getTitle().toLowerCase().contains(search.toLowerCase())))
                .collect(Collectors.toList());
    }

    @GetMapping("/{id}")
    @Transactional(readOnly = true)
    public Task getTask(@PathVariable String id) {
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "Task not found"));
        task.getSubtasks().size();
        task.getComments().size();
        task.getTags().size();
        return task;
    }

    @PostMapping
    @Transactional
    public Task createTask(@RequestBody TaskRequest req) {
        Task task = new Task();
        applyRequest(task, req);
        taskRepository.save(task);
        logActivity(task, task.getAssignee(), "CREATED_TASK", null, task.getStatus() != null ? task.getStatus().getValue() : null);
        return task;
    }

    @PutMapping("/{id}")
    @Transactional
    public Task updateTask(@PathVariable String id, @RequestBody TaskRequest req) {
        Task task = findTask(id);
        String oldStatus = task.getStatus() != null ? task.getStatus().getValue() : null;
        applyRequest(task, req);
        taskRepository.save(task);
        if (req.getStatus() != null && !req.getStatus().equalsIgnoreCase(oldStatus)) {
            logActivity(task, task.getAssignee(), "UPDATED_TASK", oldStatus, task.getStatus().getValue());
        }
        return task;
    }

    @PatchMapping("/{id}/status")
    @Transactional
    public Task updateStatus(@PathVariable String id, @RequestBody StatusUpdateRequest req) {
        Task task = findTask(id);
        String old = task.getStatus() != null ? task.getStatus().getValue() : null;
        task.setStatus(TaskStatus.fromValue(req.getStatus()));
        taskRepository.save(task);
        logActivity(task, task.getAssignee(), "CHANGED_STATUS", old, task.getStatus().getValue());
        return task;
    }

    @PatchMapping("/{id}/order")
    @Transactional
    public Task updateOrder(@PathVariable String id, @RequestBody OrderUpdateRequest req) {
        Task task = findTask(id);
        task.setOrderIndex(req.getNewOrderIndex());
        taskRepository.save(task);
        return task;
    }

    @DeleteMapping("/{id}")
    @Transactional
    public ResponseEntity<Void> deleteTask(@PathVariable String id) {
        Task task = findTask(id);
        task.setDeletedAt(LocalDateTime.now());
        taskRepository.save(task);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{id}/comments")
    @Transactional
    public TaskComment addComment(@PathVariable String id, @RequestBody CommentRequest req) {
        Task task = findTask(id);
        if (req.getAuthorId() == null) {
            throw new ResponseStatusException(org.springframework.http.HttpStatus.BAD_REQUEST, "authorId is required");
        }
        User author = userRepository.findById(req.getAuthorId())
                .orElseThrow(() -> new ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "User not found"));
        TaskComment comment = new TaskComment();
        comment.setTask(task);
        comment.setAuthor(author);
        comment.setContent(req.getContent());
        return taskCommentRepository.save(comment);
    }

    @PostMapping("/{id}/subtasks")
    @Transactional
    public Subtask addSubtask(@PathVariable String id, @RequestBody SubtaskRequest req) {
        Task task = findTask(id);
        Subtask subtask = new Subtask();
        subtask.setTask(task);
        subtask.setTitle(req.getTitle());
        subtask.setOrderIndex(req.getOrderIndex());
        return subtaskRepository.save(subtask);
    }

    @GetMapping("/{id}/activity")
    @Transactional(readOnly = true)
    public List<ActivityLog> getActivity(@PathVariable String id) {
        findTask(id);
        return activityLogRepository.findByTask_IdOrderByCreatedAtDesc(id);
    }

    private Task findTask(String id) {
        return taskRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "Task not found"));
    }

    private void applyRequest(Task task, TaskRequest req) {
        if (req.getTitle() != null) task.setTitle(req.getTitle());
        if (req.getDescription() != null) task.setDescription(req.getDescription());
        if (req.getStatus() != null) task.setStatus(TaskStatus.fromValue(req.getStatus()));
        if (req.getPriority() != null) task.setPriority(TaskPriority.fromValue(req.getPriority()));
        if (req.getOrderIndex() != null) task.setOrderIndex(req.getOrderIndex());
        if (req.getStartDate() != null) task.setStartDate(req.getStartDate());
        if (req.getDeadline() != null) task.setDeadline(req.getDeadline());
        if (req.getReminderAt() != null) task.setReminderAt(req.getReminderAt());

        if (req.getAssigneeId() != null) {
            User u = userRepository.findById(req.getAssigneeId()).orElse(null);
            task.setAssignee(u);
        }
        if (req.getProjectId() != null) {
            Project p = projectRepository.findById(req.getProjectId()).orElse(null);
            task.setProject(p);
        }
        if (req.getCategoryId() != null) {
            Category c = categoryRepository.findById(req.getCategoryId()).orElse(null);
            task.setCategory(c);
        }
        if (req.getTags() != null) {
            Set<Tag> tags = new HashSet<>();
            for (String name : req.getTags()) {
                Tag tag = tagRepository.findByName(name).orElseGet(() -> {
                    Tag t = new Tag();
                    t.setName(name);
                    return tagRepository.save(t);
                });
                tags.add(tag);
            }
            task.setTags(tags);
        }
    }

    private void logActivity(Task task, User user, String action, String oldVal, String newVal) {
        if (user == null) return;
        ActivityLog log = new ActivityLog();
        log.setTask(task);
        log.setUser(user);
        log.setActionType(action);
        log.setOldValue(oldVal);
        log.setNewValue(newVal);
        activityLogRepository.save(log);
    }
}

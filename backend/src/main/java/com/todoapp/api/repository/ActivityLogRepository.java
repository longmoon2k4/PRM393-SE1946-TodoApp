package com.todoapp.api.repository;

import com.todoapp.api.model.ActivityLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ActivityLogRepository extends JpaRepository<ActivityLog, String> {
    List<ActivityLog> findByTask_IdOrderByCreatedAtDesc(String taskId);
}

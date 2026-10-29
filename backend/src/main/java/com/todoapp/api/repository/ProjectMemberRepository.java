package com.todoapp.api.repository;

import com.todoapp.api.model.ProjectMember;
import com.todoapp.api.model.ProjectMemberId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ProjectMemberRepository extends JpaRepository<ProjectMember, ProjectMemberId> {
}

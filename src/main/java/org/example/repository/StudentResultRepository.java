package org.example.repository;

import org.example.model.StudentResult;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class StudentResultRepository {

    private final Connection connection;

    public StudentResultRepository(Connection connection) {
        this.connection = connection;
    }

    public List<StudentResult> findAll() throws SQLException {
        String sql = """
                SELECT
                    enrollment_id,
                    student_id,
                    first_name,
                    last_name,
                    course_title,
                    progress_percent,
                    score_percent
                FROM public.v_student_results
                ORDER BY enrollment_id
                """;

        List<StudentResult> results = new ArrayList<>();

        try (
                var statement = connection.prepareStatement(sql);
                var rows = statement.executeQuery()
        ) {
            while (rows.next()) {
                results.add(new StudentResult(
                        rows.getLong("enrollment_id"),
                        rows.getLong("student_id"),
                        rows.getString("first_name"),
                        rows.getString("last_name"),
                        rows.getString("course_title"),
                        rows.getBigDecimal("progress_percent"),
                        rows.getBigDecimal("score_percent")
                ));
            }
        }

        return results;
    }
}
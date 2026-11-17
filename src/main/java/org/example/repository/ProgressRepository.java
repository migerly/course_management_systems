package org.example.repository;

import java.sql.Connection;
import java.sql.SQLException;

public class ProgressRepository {

    private final Connection connection;

    public ProgressRepository(Connection connection) {
        this.connection = connection;
    }

    public void completeLesson(
            long enrollmentId,
            long lessonId,
            long actorId
    ) throws SQLException {

        String sql = """
                CALL public.complete_lesson(?, ?, ?)
                """;

        try (var statement = connection.prepareStatement(sql)) {
            statement.setLong(1, enrollmentId);
            statement.setLong(2, lessonId);
            statement.setLong(3, actorId);
            statement.execute();
        }
    }
}
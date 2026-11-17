package org.example.repository;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;

public class SubmissionRepository {

    private final Connection connection;

    public SubmissionRepository(Connection connection) {
        this.connection = connection;
    }

    public long submit(
            long assignmentId,
            long enrollmentId,
            String answerText,
            String attachmentUrl,
            long actorId
    ) throws SQLException {

        String sql = """
                CALL public.submit_assignment(?, ?, ?, ?, ?, ?)
                """;

        try (var statement = connection.prepareStatement(sql)) {
            statement.setLong(1, assignmentId);
            statement.setLong(2, enrollmentId);
            statement.setString(3, answerText);
            statement.setString(4, attachmentUrl);
            statement.setLong(5, actorId);

            // Початкове значення INOUT-параметра.
            statement.setNull(6, Types.BIGINT);

            // PostgreSQL повертає INOUT-параметр як рядок результату.
            try (var result = statement.executeQuery()) {
                if (!result.next()) {
                    throw new SQLException(
                            "Процедура не повернула ідентифікатор роботи."
                    );
                }

                return result.getLong(1);
            }
        }
    }
}
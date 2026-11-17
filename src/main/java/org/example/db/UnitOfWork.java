package org.example.db;

import org.example.repository.ProgressRepository;
import org.example.repository.StudentResultRepository;
import org.example.repository.SubmissionRepository;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class UnitOfWork implements AutoCloseable {

    private final Connection connection;
    private boolean committed;

    private final SubmissionRepository submissions;
    private final ProgressRepository progress;
    private final StudentResultRepository results;

    private UnitOfWork(Connection connection) {
        this.connection = connection;

        submissions = new SubmissionRepository(connection);
        progress = new ProgressRepository(connection);
        results = new StudentResultRepository(connection);
    }

    public static UnitOfWork open() throws SQLException {
        String url = requiredEnv("DB_URL");
        String user = requiredEnv("DB_USER");
        String password = requiredEnv("DB_PASSWORD");

        Connection connection =
                DriverManager.getConnection(url, user, password);

        try {
            connection.setAutoCommit(false);
            return new UnitOfWork(connection);
        } catch (SQLException | RuntimeException exception) {
            try {
                connection.close();
            } catch (SQLException closeException) {
                exception.addSuppressed(closeException);
            }

            throw exception;
        }
    }

    private static String requiredEnv(String name) {
        String value = System.getenv(name);

        if (value == null || value.isBlank()) {
            throw new IllegalStateException(
                    "Не задано змінну середовища " + name
            );
        }

        return value;
    }

    public SubmissionRepository submissions() {
        ensureActive();
        return submissions;
    }

    public ProgressRepository progress() {
        ensureActive();
        return progress;
    }

    public StudentResultRepository results() {
        ensureActive();
        return results;
    }

    public void commit() throws SQLException {
        ensureActive();
        connection.commit();
        committed = true;
    }

    private void ensureActive() {
        if (committed) {
            throw new IllegalStateException(
                    "Цей Unit of Work уже завершений."
            );
        }
    }

    @Override
    public void close() throws SQLException {
        SQLException failure = null;

        if (!committed) {
            try {
                connection.rollback();
            } catch (SQLException exception) {
                failure = exception;
            }
        }

        try {
            connection.close();
        } catch (SQLException exception) {
            if (failure == null) {
                failure = exception;
            } else {
                failure.addSuppressed(exception);
            }
        }

        if (failure != null) {
            throw failure;
        }
    }
}
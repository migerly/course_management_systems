package org.example.model;

import java.math.BigDecimal;

public record StudentResult(
        long enrollmentId,
        long studentId,
        String firstName,
        String lastName,
        String courseTitle,
        BigDecimal progressPercent,
        BigDecimal scorePercent
) {
}
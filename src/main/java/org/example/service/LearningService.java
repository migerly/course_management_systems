package org.example.service;

import org.example.db.UnitOfWork;

import java.sql.SQLException;

public class LearningService {

    public long submitAndComplete(
            long enrollmentId,
            long assignmentId,
            long lessonId,
            long actorId,
            String answerText
    ) throws SQLException {

        try (var unit = UnitOfWork.open()) {
            long submissionId = unit.submissions().submit(
                    assignmentId,
                    enrollmentId,
                    answerText,
                    null,
                    actorId
            );

            unit.progress().completeLesson(
                    enrollmentId,
                    lessonId,
                    actorId
            );

            unit.commit();

            return submissionId;
        }
    }
}
package org.example;

import org.example.db.UnitOfWork;
import org.example.service.LearningService;

import java.sql.SQLException;

public class Main {

    public static void main(String[] args) {
        try {
            if (args.length == 5) {
                long enrollmentId = Long.parseLong(args[0]);
                long assignmentId = Long.parseLong(args[1]);
                long lessonId = Long.parseLong(args[2]);
                long studentId = Long.parseLong(args[3]);
                String answerText = args[4];

                var service = new LearningService();

                long submissionId = service.submitAndComplete(
                        enrollmentId,
                        assignmentId,
                        lessonId,
                        studentId,
                        answerText
                );

                System.out.println(
                        "Роботу збережено, урок завершено. ID роботи: "
                                + submissionId
                );
            } else if (args.length != 0) {
                System.err.println(
                        "Потрібно 5 аргументів: "
                                + "enrollmentId assignmentId lessonId studentId "
                                + "\"1 1 1 7\""
                );
                return;
            }

            printResults();

        } catch (NumberFormatException exception) {
            System.err.println(
                    "Перші чотири аргументи мають бути цілими числами."
            );
        } catch (SQLException exception) {
            System.err.println("Помилка БД: " + exception.getMessage());
            System.err.println("SQLState: " + exception.getSQLState());
        } catch (IllegalStateException exception) {
            System.err.println(exception.getMessage());
        }
    }

    private static void printResults() throws SQLException {
        try (var unit = UnitOfWork.open()) {
            var results = unit.results().findAll();

            for (var result : results) {
                System.out.printf(
                        "%s %s | %s | Прогрес: %s%% | Результат: %s%%%n",
                        result.firstName(),
                        result.lastName(),
                        result.courseTitle(),
                        result.progressPercent(),
                        result.scorePercent()
                );
            }

            if (results.isEmpty()) {
                System.out.println("Записів студентів немає.");
            }

            unit.commit();
        }
    }
}
CREATE TABLE users (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email varchar(254) NOT NULL UNIQUE,
    password_hash text NOT NULL,
    first_name varchar(100) NOT NULL,
    last_name varchar(100) NOT NULL,

    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint REFERENCES users(id),

    deleted_at timestamptz,
    deleted_by bigint REFERENCES users(id),

    CONSTRAINT users_email_normalized
        CHECK (
            email = lower(btrim(email))
            AND email <> ''
        ),

    CONSTRAINT users_first_name_not_blank
        CHECK (btrim(first_name) <> ''),

    CONSTRAINT users_last_name_not_blank
        CHECK (btrim(last_name) <> ''),

    CONSTRAINT users_password_hash_not_blank
        CHECK (btrim(password_hash) <> ''),

    CONSTRAINT users_deletion_consistent
        CHECK (
            (deleted_at IS NULL AND deleted_by IS NULL)
            OR
            (deleted_at IS NOT NULL AND deleted_by IS NOT NULL)
        )
);

CREATE TABLE roles (
    id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code varchar(30) NOT NULL UNIQUE,
    name varchar(100) NOT NULL,

    CONSTRAINT roles_code_allowed
        CHECK (code IN ('ADMIN', 'INSTRUCTOR', 'STUDENT')),

    CONSTRAINT roles_name_not_blank
        CHECK (btrim(name) <> '')
);

CREATE TABLE user_roles (
    user_id bigint NOT NULL REFERENCES users(id),
    role_id smallint NOT NULL REFERENCES roles(id),

    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE categories (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(100) NOT NULL UNIQUE,
    description text,

    CONSTRAINT categories_name_not_blank
        CHECK (btrim(name) <> '')
);

CREATE TABLE courses (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id bigint NOT NULL REFERENCES categories(id),
    title varchar(200) NOT NULL,
    description text,
    status varchar(20) NOT NULL DEFAULT 'draft',

    created_by bigint NOT NULL REFERENCES users(id),
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint NOT NULL REFERENCES users(id),

    deleted_at timestamptz,
    deleted_by bigint REFERENCES users(id),

    CONSTRAINT courses_title_not_blank
        CHECK (btrim(title) <> ''),

    CONSTRAINT courses_status_allowed
        CHECK (status IN ('draft', 'published', 'archived')),

    CONSTRAINT courses_deletion_consistent
        CHECK (
            (deleted_at IS NULL AND deleted_by IS NULL)
            OR
            (deleted_at IS NOT NULL AND deleted_by IS NOT NULL)
        )
);

CREATE TABLE course_offerings (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_id bigint NOT NULL REFERENCES courses(id),
    name varchar(150) NOT NULL,
    starts_on date NOT NULL,
    ends_on date NOT NULL,
    status varchar(20) NOT NULL DEFAULT 'planned',

    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint NOT NULL REFERENCES users(id),

    CONSTRAINT offerings_course_name_unique
        UNIQUE (course_id, name),

    CONSTRAINT offerings_name_not_blank
        CHECK (btrim(name) <> ''),

    CONSTRAINT offerings_dates_valid
        CHECK (ends_on >= starts_on),

    CONSTRAINT offerings_status_allowed
        CHECK (
            status IN (
                'planned',
                'open',
                'ongoing',
                'completed',
                'cancelled'
            )
        )
);

CREATE TABLE offering_instructors (
    offering_id bigint NOT NULL REFERENCES course_offerings(id),
    instructor_id bigint NOT NULL REFERENCES users(id),

    PRIMARY KEY (offering_id, instructor_id)
);

CREATE TABLE enrollments (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    offering_id bigint NOT NULL REFERENCES course_offerings(id),
    student_id bigint NOT NULL REFERENCES users(id),
    status varchar(20) NOT NULL DEFAULT 'active',

    enrolled_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint NOT NULL REFERENCES users(id),

    CONSTRAINT enrollments_offering_student_unique
        UNIQUE (offering_id, student_id),

    CONSTRAINT enrollments_status_allowed
        CHECK (status IN ('active', 'completed', 'withdrawn'))
);

INSERT INTO roles (code, name)
VALUES
    ('ADMIN', 'Адміністратор'),
    ('INSTRUCTOR', 'Викладач'),
    ('STUDENT', 'Студент');

CREATE TABLE modules (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_id bigint NOT NULL REFERENCES courses(id),
    title varchar(200) NOT NULL,
    position integer NOT NULL,

    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint NOT NULL REFERENCES users(id),
    deleted_at timestamptz,
    deleted_by bigint REFERENCES users(id),

    CONSTRAINT modules_title_not_blank
        CHECK (btrim(title) <> ''),

    CONSTRAINT modules_position_positive
        CHECK (position > 0),

    CONSTRAINT modules_position_unique
        UNIQUE (course_id, position),

    CONSTRAINT modules_deletion_consistent
        CHECK (
            (deleted_at IS NULL AND deleted_by IS NULL)
            OR
            (deleted_at IS NOT NULL AND deleted_by IS NOT NULL)
        )
);

CREATE TABLE lessons (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    module_id bigint NOT NULL REFERENCES modules(id),
    title varchar(200) NOT NULL,
    content text,
    position integer NOT NULL,

    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint NOT NULL REFERENCES users(id),
    deleted_at timestamptz,
    deleted_by bigint REFERENCES users(id),

    CONSTRAINT lessons_title_not_blank
        CHECK (btrim(title) <> ''),

    CONSTRAINT lessons_position_positive
        CHECK (position > 0),

    CONSTRAINT lessons_position_unique
        UNIQUE (module_id, position),

    CONSTRAINT lessons_deletion_consistent
        CHECK (
            (deleted_at IS NULL AND deleted_by IS NULL)
            OR
            (deleted_at IS NOT NULL AND deleted_by IS NOT NULL)
        )
);

CREATE TABLE lesson_materials (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lesson_id bigint NOT NULL REFERENCES lessons(id),
    title varchar(200) NOT NULL,
    url text NOT NULL,
    material_type varchar(20) NOT NULL,

    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint NOT NULL REFERENCES users(id),
    deleted_at timestamptz,
    deleted_by bigint REFERENCES users(id),

    CONSTRAINT materials_title_not_blank
        CHECK (btrim(title) <> ''),

    CONSTRAINT materials_url_not_blank
        CHECK (btrim(url) <> ''),

    CONSTRAINT materials_type_allowed
        CHECK (material_type IN ('document', 'video', 'link')),

    CONSTRAINT materials_deletion_consistent
        CHECK (
            (deleted_at IS NULL AND deleted_by IS NULL)
            OR
            (deleted_at IS NOT NULL AND deleted_by IS NOT NULL)
        )
);

CREATE TABLE assignments (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    offering_id bigint NOT NULL REFERENCES course_offerings(id),
    lesson_id bigint REFERENCES lessons(id),
    title varchar(200) NOT NULL,
    description text NOT NULL,
    due_at timestamptz,
    max_score numeric(7,2) NOT NULL,

    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint NOT NULL REFERENCES users(id),
    deleted_at timestamptz,
    deleted_by bigint REFERENCES users(id),

    CONSTRAINT assignments_title_not_blank
        CHECK (btrim(title) <> ''),

    CONSTRAINT assignments_description_not_blank
        CHECK (btrim(description) <> ''),

    CONSTRAINT assignments_max_score_positive
        CHECK (
            max_score > 0
            AND max_score <> 'NaN'::numeric
        ),

    CONSTRAINT assignments_deletion_consistent
        CHECK (
            (deleted_at IS NULL AND deleted_by IS NULL)
            OR
            (deleted_at IS NOT NULL AND deleted_by IS NOT NULL)
        )
);

CREATE TABLE submissions (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    assignment_id bigint NOT NULL REFERENCES assignments(id),
    enrollment_id bigint NOT NULL REFERENCES enrollments(id),
    attempt_no integer NOT NULL,
    answer_text text,
    attachment_url text,
    submitted_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT submissions_attempt_positive
        CHECK (attempt_no > 0),

    CONSTRAINT submissions_attempt_unique
        UNIQUE (assignment_id, enrollment_id, attempt_no),

    CONSTRAINT submissions_answer_required
        CHECK (
            COALESCE(btrim(answer_text), '') <> ''
            OR
            COALESCE(btrim(attachment_url), '') <> ''
        )
);

CREATE TABLE grades (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    submission_id bigint NOT NULL UNIQUE REFERENCES submissions(id),
    graded_by bigint NOT NULL REFERENCES users(id),
    score numeric(7,2) NOT NULL,
    feedback text,
    graded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint NOT NULL REFERENCES users(id),

    CONSTRAINT grades_score_nonnegative
        CHECK (
            score >= 0
            AND score <> 'NaN'::numeric
        )
);

CREATE TABLE lesson_progress (
    enrollment_id bigint NOT NULL REFERENCES enrollments(id),
    lesson_id bigint NOT NULL REFERENCES lessons(id),
    completed_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (enrollment_id, lesson_id)
);

CREATE TABLE announcements (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    offering_id bigint NOT NULL REFERENCES course_offerings(id),
    author_id bigint NOT NULL REFERENCES users(id),
    title varchar(200) NOT NULL,
    body text NOT NULL,
    published_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint NOT NULL REFERENCES users(id),
    deleted_at timestamptz,
    deleted_by bigint REFERENCES users(id),

    CONSTRAINT announcements_title_not_blank
        CHECK (btrim(title) <> ''),

    CONSTRAINT announcements_body_not_blank
        CHECK (btrim(body) <> ''),

    CONSTRAINT announcements_deletion_consistent
        CHECK (
            (deleted_at IS NULL AND deleted_by IS NULL)
            OR
            (deleted_at IS NOT NULL AND deleted_by IS NOT NULL)
        )
);

CREATE TABLE discussions (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    offering_id bigint NOT NULL REFERENCES course_offerings(id),
    author_id bigint NOT NULL REFERENCES users(id),
    title varchar(200) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint NOT NULL REFERENCES users(id),
    deleted_at timestamptz,
    deleted_by bigint REFERENCES users(id),

    CONSTRAINT discussions_title_not_blank
        CHECK (btrim(title) <> ''),

    CONSTRAINT discussions_deletion_consistent
        CHECK (
            (deleted_at IS NULL AND deleted_by IS NULL)
            OR
            (deleted_at IS NOT NULL AND deleted_by IS NOT NULL)
        )
);

CREATE TABLE discussion_messages (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    discussion_id bigint NOT NULL REFERENCES discussions(id),
    author_id bigint NOT NULL REFERENCES users(id),
    body text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by bigint NOT NULL REFERENCES users(id),
    deleted_at timestamptz,
    deleted_by bigint REFERENCES users(id),

    CONSTRAINT messages_body_not_blank
        CHECK (btrim(body) <> ''),

    CONSTRAINT messages_deletion_consistent
        CHECK (
            (deleted_at IS NULL AND deleted_by IS NULL)
            OR
            (deleted_at IS NOT NULL AND deleted_by IS NOT NULL)
        )
);

SELECT table_name
FROM information_schema.tables
WHERE table_schema = current_schema()
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := statement_timestamp();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_courses_updated_at
BEFORE UPDATE ON courses
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_course_offerings_updated_at
BEFORE UPDATE ON course_offerings
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_enrollments_updated_at
BEFORE UPDATE ON enrollments
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_modules_updated_at
BEFORE UPDATE ON modules
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_lessons_updated_at
BEFORE UPDATE ON lessons
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_lesson_materials_updated_at
BEFORE UPDATE ON lesson_materials
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_assignments_updated_at
BEFORE UPDATE ON assignments
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_grades_updated_at
BEFORE UPDATE ON grades
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_announcements_updated_at
BEFORE UPDATE ON announcements
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_discussions_updated_at
BEFORE UPDATE ON discussions
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_discussion_messages_updated_at
BEFORE UPDATE ON discussion_messages
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

SELECT
    event_object_table AS table_name,
    trigger_name
FROM information_schema.triggers
WHERE trigger_schema = current_schema()
  AND action_statement LIKE '%set_updated_at%'
ORDER BY event_object_table;

INSERT INTO users (
    email,
    password_hash,
    first_name,
    last_name
)
VALUES (
    'trigger-test@example.invalid',
    'test-placeholder-not-for-login',
    'Test',
    'User'
)
RETURNING id, created_at, updated_at;

UPDATE users
SET
    first_name = 'Updated',
    updated_by = id
WHERE email = 'trigger-test@example.invalid'
RETURNING id, first_name, created_at, updated_at, updated_by;

DELETE FROM users
WHERE id = 1
  AND email = 'trigger-test@example.invalid'
RETURNING id, email;

CREATE OR REPLACE FUNCTION assert_active_admin(p_actor_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM users u
        JOIN user_roles ur ON ur.user_id = u.id
        JOIN roles r ON r.id = ur.role_id
        WHERE u.id = p_actor_id
          AND u.deleted_at IS NULL
          AND r.code = 'ADMIN'
    ) THEN
        RAISE EXCEPTION
            'Дію може виконувати лише активний адміністратор.'
            USING ERRCODE = '42501';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE soft_delete_course(
    p_course_id bigint,
    p_actor_id bigint
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_deleted_at timestamptz;
BEGIN
    PERFORM assert_active_admin(p_actor_id);

    -- Блокуємо курс до завершення транзакції,
    -- щоб одночасні зміни не конфліктували.
    SELECT c.deleted_at
    INTO v_deleted_at
    FROM courses c
    WHERE c.id = p_course_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Курс з id % не знайдено.', p_course_id;
    END IF;

    IF v_deleted_at IS NOT NULL THEN
        RAISE EXCEPTION 'Курс з id % уже видалений.', p_course_id;
    END IF;

    UPDATE courses
    SET
        deleted_at = statement_timestamp(),
        deleted_by = p_actor_id,
        updated_by = p_actor_id
    WHERE id = p_course_id;
END;
$$;

CREATE OR REPLACE PROCEDURE restore_course(
    p_course_id bigint,
    p_actor_id bigint
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_deleted_at timestamptz;
BEGIN
    PERFORM assert_active_admin(p_actor_id);

    SELECT c.deleted_at
    INTO v_deleted_at
    FROM courses c
    WHERE c.id = p_course_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Курс з id % не знайдено.', p_course_id;
    END IF;

    IF v_deleted_at IS NULL THEN
        RAISE EXCEPTION 'Курс з id % не є видаленим.', p_course_id;
    END IF;

    UPDATE courses
    SET
        deleted_at = NULL,
        deleted_by = NULL,
        updated_by = p_actor_id
    WHERE id = p_course_id;
END;
$$;

CREATE OR REPLACE VIEW v_active_courses AS
SELECT
    c.id,
    c.category_id,
    cat.name AS category_name,
    c.title,
    c.description,
    c.status,
    c.created_by,
    c.created_at,
    c.updated_at,
    c.updated_by
FROM courses c
JOIN categories cat ON cat.id = c.category_id
WHERE c.deleted_at IS NULL;

BEGIN;

DO $$
DECLARE
    v_admin_id bigint;
    v_category_id bigint;
    v_course_id bigint;
BEGIN
    INSERT INTO users (
        email, password_hash, first_name, last_name
    )
    VALUES (
        'soft-delete-test@example.invalid',
        'test-placeholder-not-for-login',
        'Test',
        'Admin'
    )
    RETURNING id INTO v_admin_id;

    INSERT INTO user_roles (user_id, role_id)
    SELECT v_admin_id, id
    FROM roles
    WHERE code = 'ADMIN';

    INSERT INTO categories (name)
    VALUES ('Тестова категорія Soft delete')
    RETURNING id INTO v_category_id;

    INSERT INTO courses (
        category_id, title, created_by, updated_by
    )
    VALUES (
        v_category_id,
        'Тестовий курс Soft delete',
        v_admin_id,
        v_admin_id
    )
    RETURNING id INTO v_course_id;

    CALL soft_delete_course(v_course_id, v_admin_id);

    IF EXISTS (
        SELECT 1 FROM v_active_courses
        WHERE id = v_course_id
    ) THEN
        RAISE EXCEPTION 'Помилка: видалений курс видимий.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM courses
        WHERE id = v_course_id
          AND deleted_at IS NOT NULL
          AND deleted_by = v_admin_id
          AND updated_by = v_admin_id
    ) THEN
        RAISE EXCEPTION 'Помилка: дані видалення не збережені.';
    END IF;

    RAISE NOTICE 'Soft delete: перевірку пройдено.';

    CALL restore_course(v_course_id, v_admin_id);

    IF NOT EXISTS (
        SELECT 1 FROM v_active_courses
        WHERE id = v_course_id
    ) THEN
        RAISE EXCEPTION 'Помилка: відновлений курс не видимий.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM courses
        WHERE id = v_course_id
          AND deleted_at IS NULL
          AND deleted_by IS NULL
          AND updated_by = v_admin_id
    ) THEN
        RAISE EXCEPTION 'Помилка: дані відновлення некоректні.';
    END IF;

    RAISE NOTICE 'Відновлення: перевірку пройдено.';
END;
$$;

ROLLBACK;

CREATE OR REPLACE VIEW v_active_modules AS
SELECT
    m.id,
    m.course_id,
    m.title,
    m.position,
    m.created_at,
    m.updated_at,
    m.updated_by
FROM modules m
JOIN courses c ON c.id = m.course_id
WHERE m.deleted_at IS NULL
  AND c.deleted_at IS NULL;

CREATE OR REPLACE VIEW v_active_lessons AS
SELECT
    l.id,
    l.module_id,
    m.course_id,
    l.title,
    l.content,
    l.position,
    l.created_at,
    l.updated_at,
    l.updated_by
FROM lessons l
JOIN modules m ON m.id = l.module_id
JOIN courses c ON c.id = m.course_id
WHERE l.deleted_at IS NULL
  AND m.deleted_at IS NULL
  AND c.deleted_at IS NULL;

CREATE OR REPLACE VIEW v_active_lesson_materials AS
SELECT
    lm.id,
    lm.lesson_id,
    l.module_id,
    m.course_id,
    lm.title,
    lm.url,
    lm.material_type,
    lm.created_at,
    lm.updated_at,
    lm.updated_by
FROM lesson_materials lm
JOIN lessons l ON l.id = lm.lesson_id
JOIN modules m ON m.id = l.module_id
JOIN courses c ON c.id = m.course_id
WHERE lm.deleted_at IS NULL
  AND l.deleted_at IS NULL
  AND m.deleted_at IS NULL
  AND c.deleted_at IS NULL;

CREATE INDEX idx_courses_active_category
ON courses USING btree (category_id)
WHERE deleted_at IS NULL;

CREATE INDEX idx_enrollments_student
ON enrollments USING btree (student_id);

CREATE INDEX idx_courses_active_search
ON courses USING gin (
    to_tsvector(
        'simple'::regconfig,
        title || ' ' || COALESCE(description, '')
    )
)
WHERE deleted_at IS NULL;

SELECT table_name
FROM information_schema.views
WHERE table_schema = current_schema()
ORDER BY table_name;

SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = current_schema()
  AND indexname IN (
      'idx_courses_active_category',
      'idx_enrollments_student',
      'idx_courses_active_search'
  )
ORDER BY indexname;

SELECT id, title, category_name
FROM v_active_courses
WHERE to_tsvector(
    'simple'::regconfig,
    title || ' ' || COALESCE(description, '')
) @@ plainto_tsquery('simple'::regconfig, 'Java');

SELECT
    (SELECT count(*) FROM public.courses) AS total_courses,
    (SELECT count(*) FROM public.v_active_courses) AS active_courses;

SELECT id, title, category_name
FROM public.v_active_courses;

CREATE OR REPLACE PROCEDURE create_course(
    p_category_id bigint,
    p_title text,
    p_description text,
    p_actor_id bigint,
    INOUT p_course_id bigint
)
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM assert_active_admin(p_actor_id);

    IF p_title IS NULL OR btrim(p_title) = '' THEN
        RAISE EXCEPTION 'Назва курсу не може бути порожньою.';
    END IF;

    IF char_length(btrim(p_title)) > 200 THEN
        RAISE EXCEPTION 'Назва курсу не може перевищувати 200 символів.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM categories
        WHERE id = p_category_id
    ) THEN
        RAISE EXCEPTION 'Категорію з id % не знайдено.', p_category_id;
    END IF;

    INSERT INTO courses (
        category_id,
        title,
        description,
        created_by,
        updated_by
    )
    VALUES (
        p_category_id,
        btrim(p_title),
        p_description,
        p_actor_id,
        p_actor_id
    )
    RETURNING id INTO p_course_id;
END;
$$;

BEGIN;

DO $$
DECLARE
    v_admin_id bigint;
    v_category_id bigint;
    v_course_id bigint;
BEGIN
    -- Створюємо демонстраційного користувача.
    INSERT INTO users (
        email,
        password_hash,
        first_name,
        last_name
    )
    VALUES (
        'admin@example.invalid',
        '!disabled-demo-account',
        'Demo',
        'Admin'
    )
    ON CONFLICT (email) DO NOTHING;

    SELECT id
    INTO STRICT v_admin_id
    FROM users
    WHERE email = 'admin@example.invalid'
      AND deleted_at IS NULL;

    -- Призначаємо роль адміністратора.
    INSERT INTO user_roles (user_id, role_id)
    SELECT v_admin_id, id
    FROM roles
    WHERE code = 'ADMIN'
    ON CONFLICT (user_id, role_id) DO NOTHING;

    -- Створюємо категорію.
    INSERT INTO categories (name, description)
    VALUES (
        'Програмування',
        'Курси з розробки програмного забезпечення'
    )
    ON CONFLICT (name) DO NOTHING;

    SELECT id
    INTO STRICT v_category_id
    FROM categories
    WHERE name = 'Програмування';

    -- Не дублюємо демонстраційний курс при повторному запуску.
    IF NOT EXISTS (
        SELECT 1
        FROM courses
        WHERE title = 'Основи Java'
          AND category_id = v_category_id
          AND created_by = v_admin_id
    ) THEN
        CALL create_course(
            v_category_id,
            'Основи Java',
            'Змінні, умови, цикли, класи та об’єкти.',
            v_admin_id,
            v_course_id
        );
    END IF;
END;
$$;

COMMIT;

SELECT
    id,
    title,
    category_name,
    status,
    created_by,
    updated_by
FROM public.v_active_courses
ORDER BY id;

SELECT id, title, category_name
FROM public.v_active_courses
WHERE to_tsvector(
    'simple'::regconfig,
    title || ' ' || COALESCE(description, '')
) @@ plainto_tsquery('simple'::regconfig, 'Java');

CREATE OR REPLACE FUNCTION assert_active_role(
    p_user_id bigint,
    p_role_code text
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM users u
        JOIN user_roles ur ON ur.user_id = u.id
        JOIN roles r ON r.id = ur.role_id
        WHERE u.id = p_user_id
          AND u.deleted_at IS NULL
          AND r.code = p_role_code
    ) THEN
        RAISE EXCEPTION
            'Користувач % відсутній, видалений або не має ролі %.',
            p_user_id, p_role_code;
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE create_course_offering(
    p_course_id bigint,
    p_name text,
    p_starts_on date,
    p_ends_on date,
    p_actor_id bigint,
    INOUT p_offering_id bigint
)
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM assert_active_admin(p_actor_id);

    IF p_name IS NULL
       OR btrim(p_name) = ''
       OR char_length(btrim(p_name)) > 150 THEN
        RAISE EXCEPTION
            'Назва проведення повинна містити від 1 до 150 символів.';
    END IF;

    IF p_starts_on IS NULL
       OR p_ends_on IS NULL
       OR p_ends_on < p_starts_on THEN
        RAISE EXCEPTION 'Некоректні дати проведення.';
    END IF;

    PERFORM 1
    FROM courses
    WHERE id = p_course_id
      AND deleted_at IS NULL
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Курс відсутній або видалений.';
    END IF;

    INSERT INTO course_offerings (
        course_id, name, starts_on, ends_on, updated_by
    )
    VALUES (
        p_course_id,
        btrim(p_name),
        p_starts_on,
        p_ends_on,
        p_actor_id
    )
    RETURNING id INTO p_offering_id;
END;
$$;

CREATE OR REPLACE PROCEDURE assign_offering_instructor(
    p_offering_id bigint,
    p_instructor_id bigint,
    p_actor_id bigint
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status varchar(20);
    v_course_id bigint;
BEGIN
    PERFORM assert_active_admin(p_actor_id);
    PERFORM assert_active_role(p_instructor_id, 'INSTRUCTOR');

    SELECT status, course_id
    INTO v_status, v_course_id
    FROM course_offerings
    WHERE id = p_offering_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Проведення курсу не знайдено.';
    END IF;

    PERFORM 1
    FROM courses
    WHERE id = v_course_id
      AND deleted_at IS NULL
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Курс видалений.';
    END IF;

    IF v_status IN ('completed', 'cancelled') THEN
        RAISE EXCEPTION
            'Не можна призначити викладача: проведення завершене або скасоване.';
    END IF;

    INSERT INTO offering_instructors (offering_id, instructor_id)
    VALUES (p_offering_id, p_instructor_id)
    ON CONFLICT (offering_id, instructor_id) DO NOTHING;
END;
$$;

CREATE OR REPLACE PROCEDURE enroll_student(
    p_offering_id bigint,
    p_student_id bigint,
    p_actor_id bigint,
    INOUT p_enrollment_id bigint
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status varchar(20);
    v_ends_on date;
    v_course_id bigint;
BEGIN
    PERFORM assert_active_admin(p_actor_id);
    PERFORM assert_active_role(p_student_id, 'STUDENT');

    SELECT status, ends_on, course_id
    INTO v_status, v_ends_on, v_course_id
    FROM course_offerings
    WHERE id = p_offering_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Проведення курсу не знайдено.';
    END IF;

    PERFORM 1
    FROM courses
    WHERE id = v_course_id
      AND deleted_at IS NULL
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Курс видалений.';
    END IF;

    IF v_status NOT IN ('open', 'ongoing')
       OR v_ends_on < CURRENT_DATE THEN
        RAISE EXCEPTION 'Запис на це проведення закритий.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM enrollments
        WHERE offering_id = p_offering_id
          AND student_id = p_student_id
    ) THEN
        RAISE EXCEPTION
            'Студент уже має запис на це проведення.';
    END IF;

    INSERT INTO enrollments (
        offering_id, student_id, updated_by
    )
    VALUES (
        p_offering_id, p_student_id, p_actor_id
    )
    RETURNING id INTO p_enrollment_id;
END;
$$;

CREATE OR REPLACE VIEW v_course_enrollments AS
SELECT
    e.id AS enrollment_id,
    e.student_id,
    u.first_name,
    u.last_name,
    e.offering_id,
    co.name AS offering_name,
    c.id AS course_id,
    c.title AS course_title,
    e.status,
    e.enrolled_at,
    e.updated_at,
    e.updated_by
FROM enrollments e
JOIN users u ON u.id = e.student_id
JOIN course_offerings co ON co.id = e.offering_id
JOIN courses c ON c.id = co.course_id
WHERE u.deleted_at IS NULL
  AND c.deleted_at IS NULL;

BEGIN;

DO $$
DECLARE
    v_admin_id bigint;
    v_teacher_id bigint;
    v_student_id bigint;
    v_course_id bigint;
    v_offering_id bigint;
    v_enrollment_id bigint;
BEGIN
    SELECT id INTO STRICT v_admin_id
    FROM users
    WHERE email = 'admin@example.invalid'
      AND deleted_at IS NULL;

    PERFORM assert_active_admin(v_admin_id);

    INSERT INTO users (
        email, password_hash, first_name, last_name
    )
    VALUES
        (
            'teacher@example.invalid',
            '!disabled-demo-account',
            'Olena',
            'Koval'
        ),
        (
            'student@example.invalid',
            '!disabled-demo-account',
            'Anna',
            'Melnyk'
        )
    ON CONFLICT (email) DO NOTHING;

    SELECT id INTO STRICT v_teacher_id
    FROM users
    WHERE email = 'teacher@example.invalid'
      AND deleted_at IS NULL;

    SELECT id INTO STRICT v_student_id
    FROM users
    WHERE email = 'student@example.invalid'
      AND deleted_at IS NULL;

    INSERT INTO user_roles (user_id, role_id)
    SELECT v_teacher_id, id
    FROM roles
    WHERE code = 'INSTRUCTOR'
    ON CONFLICT DO NOTHING;

    INSERT INTO user_roles (user_id, role_id)
    SELECT v_student_id, id
    FROM roles
    WHERE code = 'STUDENT'
    ON CONFLICT DO NOTHING;

    SELECT id INTO STRICT v_course_id
    FROM courses
    WHERE title = 'Основи Java'
      AND created_by = v_admin_id
      AND deleted_at IS NULL;

    SELECT id INTO v_offering_id
    FROM course_offerings
    WHERE course_id = v_course_id
      AND name = 'Навчальна група 2026/27';

    IF v_offering_id IS NULL THEN
        CALL create_course_offering(
            v_course_id,
            'Навчальна група 2026/27',
            CURRENT_DATE,
            CURRENT_DATE + 90,
            v_admin_id,
            v_offering_id
        );

        -- Початкове налаштування демонстраційних даних.
        -- У програмі зміну статусу винесемо в окрему процедуру.
        UPDATE course_offerings
        SET status = 'open',
            updated_by = v_admin_id
        WHERE id = v_offering_id;
    END IF;

    CALL assign_offering_instructor(
        v_offering_id,
        v_teacher_id,
        v_admin_id
    );

    IF NOT EXISTS (
        SELECT 1
        FROM enrollments
        WHERE offering_id = v_offering_id
          AND student_id = v_student_id
    ) THEN
        CALL enroll_student(
            v_offering_id,
            v_student_id,
            v_admin_id,
            v_enrollment_id
        );
    END IF;
END;
$$;

COMMIT;

SELECT
    first_name,
    last_name,
    course_title,
    offering_name,
    status AS enrollment_status
FROM public.v_course_enrollments
ORDER BY enrollment_id;

SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'v_course_enrollments'
ORDER BY ordinal_position;

SELECT
    e.first_name,
    e.last_name,
    e.course_title,
    e.offering_name,
    co.status AS offering_status,
    e.status AS enrollment_status
FROM public.v_course_enrollments e
JOIN public.course_offerings co ON co.id = e.offering_id
ORDER BY e.enrollment_id;

CREATE OR REPLACE FUNCTION assert_course_editor(
    p_course_id bigint,
    p_actor_id bigint
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM 1
    FROM courses
    WHERE id = p_course_id
      AND deleted_at IS NULL
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Курс не знайдено або він видалений.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM users u
        WHERE u.id = p_actor_id
          AND u.deleted_at IS NULL
          AND (
              EXISTS (
                  SELECT 1
                  FROM user_roles ur
                  JOIN roles r ON r.id = ur.role_id
                  WHERE ur.user_id = u.id
                    AND r.code = 'ADMIN'
              )
              OR (
                  EXISTS (
                      SELECT 1
                      FROM user_roles ur
                      JOIN roles r ON r.id = ur.role_id
                      WHERE ur.user_id = u.id
                        AND r.code = 'INSTRUCTOR'
                  )
                  AND EXISTS (
                      SELECT 1
                      FROM offering_instructors oi
                      JOIN course_offerings co
                          ON co.id = oi.offering_id
                      WHERE oi.instructor_id = u.id
                        AND co.course_id = p_course_id
                        AND co.status IN (
                            'planned', 'open', 'ongoing'
                        )
                  )
              )
          )
    ) THEN
        RAISE EXCEPTION 'Немає права редагувати цей курс.'
            USING ERRCODE = '42501';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE create_module(
    p_course_id bigint,
    p_title text,
    p_position integer,
    p_actor_id bigint,
    INOUT p_module_id bigint
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Блокуємо курс на час зміни його структури.
    PERFORM 1
    FROM courses
    WHERE id = p_course_id
    FOR UPDATE;

    PERFORM assert_course_editor(p_course_id, p_actor_id);

    IF EXISTS (
        SELECT 1
        FROM course_offerings
        WHERE course_id = p_course_id
          AND status IN ('ongoing', 'completed')
    ) THEN
        RAISE EXCEPTION 'Не можна змінювати структуру курсу після початку навчання.';
    END IF;

    INSERT INTO modules (
        course_id, title, position, updated_by
    )
    VALUES (
        p_course_id, btrim(p_title), p_position, p_actor_id
    )
    RETURNING id INTO p_module_id;
END;
$$;


CREATE OR REPLACE PROCEDURE create_lesson(
    p_module_id bigint,
    p_title text,
    p_content text,
    p_position integer,
    p_actor_id bigint,
    INOUT p_lesson_id bigint
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_course_id bigint;
BEGIN
    SELECT course_id INTO v_course_id
    FROM modules
    WHERE id = p_module_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Модуль не знайдено.';
    END IF;

    PERFORM 1
    FROM courses
    WHERE id = v_course_id
    FOR UPDATE;

    PERFORM assert_course_editor(v_course_id, p_actor_id);

    PERFORM 1
    FROM modules
    WHERE id = p_module_id
      AND course_id = v_course_id
      AND deleted_at IS NULL
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Модуль видалений або змінений.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM course_offerings
        WHERE course_id = v_course_id
          AND status IN ('ongoing', 'completed')
    ) THEN
        RAISE EXCEPTION 'Не можна змінювати структуру курсу після початку навчання.';
    END IF;

    INSERT INTO lessons (
        module_id, title, content, position, updated_by
    )
    VALUES (
        p_module_id,
        btrim(p_title),
        p_content,
        p_position,
        p_actor_id
    )
    RETURNING id INTO p_lesson_id;
END;
$$;

CREATE OR REPLACE PROCEDURE create_assignment(
    p_offering_id bigint,
    p_lesson_id bigint,
    p_title text,
    p_description text,
    p_due_at timestamptz,
    p_max_score numeric,
    p_actor_id bigint,
    INOUT p_assignment_id bigint
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_course_id bigint;
    v_status varchar(20);
BEGIN
    SELECT course_id, status
    INTO v_course_id, v_status
    FROM course_offerings
    WHERE id = p_offering_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Проведення курсу не знайдено.';
    END IF;

    PERFORM assert_course_editor(v_course_id, p_actor_id);

    -- Викладач повинен бути призначений саме на це проведення.
    IF NOT EXISTS (
        SELECT 1
        FROM user_roles ur
        JOIN roles r ON r.id = ur.role_id
        WHERE ur.user_id = p_actor_id
          AND r.code = 'ADMIN'
    ) AND NOT EXISTS (
        SELECT 1
        FROM offering_instructors
        WHERE offering_id = p_offering_id
          AND instructor_id = p_actor_id
    ) THEN
        RAISE EXCEPTION 'Викладач не призначений на це проведення.';
    END IF;

    IF v_status NOT IN ('planned', 'open', 'ongoing') THEN
        RAISE EXCEPTION 'Не можна додавати завдання до завершеного або скасованого проведення.';
    END IF;

    IF p_lesson_id IS NOT NULL THEN
        PERFORM 1
        FROM lessons l
        JOIN modules m ON m.id = l.module_id
        WHERE l.id = p_lesson_id
          AND m.course_id = v_course_id
          AND l.deleted_at IS NULL
          AND m.deleted_at IS NULL
        FOR SHARE OF l, m;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Урок недоступний або належить іншому курсу.';
        END IF;
    END IF;

    INSERT INTO assignments (
        offering_id,
        lesson_id,
        title,
        description,
        due_at,
        max_score,
        updated_by
    )
    VALUES (
        p_offering_id,
        p_lesson_id,
        btrim(p_title),
        p_description,
        p_due_at,
        p_max_score,
        p_actor_id
    )
    RETURNING id INTO p_assignment_id;
END;
$$;

CREATE OR REPLACE VIEW v_active_assignments AS
SELECT
    a.id,
    a.offering_id,
    co.name AS offering_name,
    co.course_id,
    c.title AS course_title,
    a.lesson_id,
    a.title,
    a.description,
    a.due_at,
    a.max_score,
    a.created_at,
    a.updated_at,
    a.updated_by
FROM assignments a
JOIN course_offerings co ON co.id = a.offering_id
JOIN courses c ON c.id = co.course_id
WHERE a.deleted_at IS NULL
  AND c.deleted_at IS NULL
  AND (
      a.lesson_id IS NULL
      OR EXISTS (
          SELECT 1
          FROM v_active_lessons l
          WHERE l.id = a.lesson_id
            AND l.course_id = co.course_id
      )
  );


BEGIN;

DO $$
DECLARE
    v_teacher_id bigint;
    v_course_id bigint;
    v_offering_id bigint;
    v_module_id bigint;
    v_lesson_id bigint;
    v_assignment_id bigint;
BEGIN
    SELECT id INTO STRICT v_teacher_id
    FROM users
    WHERE email = 'teacher@example.invalid'
      AND deleted_at IS NULL;

    SELECT co.id, co.course_id
    INTO STRICT v_offering_id, v_course_id
    FROM course_offerings co
    JOIN courses c ON c.id = co.course_id
    WHERE co.name = 'Навчальна група 2026/27'
      AND c.title = 'Основи Java'
      AND c.deleted_at IS NULL;

    SELECT id INTO v_module_id
    FROM modules
    WHERE course_id = v_course_id
      AND position = 1;

    IF v_module_id IS NULL THEN
        CALL create_module(
            v_course_id,
            'Основи програмування',
            1,
            v_teacher_id,
            v_module_id
        );
    END IF;

    SELECT id INTO v_lesson_id
    FROM lessons
    WHERE module_id = v_module_id
      AND position = 1;

    IF v_lesson_id IS NULL THEN
        CALL create_lesson(
            v_module_id,
            'Змінні та типи даних',
            'Оголошення змінних і використання основних типів даних Java.',
            1,
            v_teacher_id,
            v_lesson_id
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM assignments
        WHERE offering_id = v_offering_id
          AND title = 'Перша програма Java'
    ) THEN
        CALL create_assignment(
            v_offering_id,
            v_lesson_id,
            'Перша програма Java',
            'Напишіть програму, яка оголошує змінні name та age і виводить їхні значення.',
            CURRENT_TIMESTAMP + INTERVAL '7 days',
            10,
            v_teacher_id,
            v_assignment_id
        );
    END IF;
END;
$$;

COMMIT;

CREATE OR REPLACE PROCEDURE public.create_module(
    p_course_id bigint,
    p_title text,
    p_position integer,
    p_actor_id bigint,
    INOUT p_module_id bigint
)
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM 1
    FROM public.courses
    WHERE id = p_course_id
    FOR UPDATE;

    PERFORM public.assert_course_editor(
        p_course_id,
        p_actor_id
    );

    IF EXISTS (
        SELECT 1
        FROM public.course_offerings
        WHERE course_id = p_course_id
          AND status IN ('ongoing', 'completed')
    ) THEN
        RAISE EXCEPTION
            'Не можна змінювати структуру курсу після початку навчання.';
    END IF;

    INSERT INTO public.modules (
        course_id,
        title,
        position,
        updated_by
    )
    VALUES (
        p_course_id,
        btrim(p_title),
        p_position,
        p_actor_id
    )
    RETURNING id INTO p_module_id;
END;
$$;

SELECT
    n.nspname AS schema_name,
    p.proname AS procedure_name,
    pg_get_function_arguments(p.oid) AS parameters
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.prokind = 'p'
  AND p.proname IN (
      'create_module',
      'create_lesson',
      'create_assignment'
  )
ORDER BY p.proname;

CREATE OR REPLACE PROCEDURE public.submit_assignment(
    p_assignment_id bigint,
    p_enrollment_id bigint,
    p_answer_text text,
    p_attachment_url text,
    p_actor_id bigint,
    INOUT p_submission_id bigint
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_student_id bigint;
    v_enrollment_offering_id bigint;
    v_enrollment_status varchar(20);

    v_assignment_offering_id bigint;
    v_lesson_id bigint;
    v_due_at timestamptz;

    v_course_id bigint;
    v_offering_status varchar(20);
    v_ends_on date;
    v_attempt_no integer;
BEGIN
    PERFORM public.assert_active_role(p_actor_id, 'STUDENT');

    -- Блокуємо запис студента, щоб одночасні спроби
    -- отримали різні номери.
    SELECT student_id, offering_id, status
    INTO
        v_student_id,
        v_enrollment_offering_id,
        v_enrollment_status
    FROM public.enrollments
    WHERE id = p_enrollment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Запис студента на курс не знайдено.';
    END IF;

    IF v_student_id <> p_actor_id THEN
        RAISE EXCEPTION 'Не можна здавати роботу від імені іншого студента.';
    END IF;

    IF v_enrollment_status <> 'active' THEN
        RAISE EXCEPTION 'Запис студента на курс неактивний.';
    END IF;

    SELECT offering_id, lesson_id, due_at
    INTO
        v_assignment_offering_id,
        v_lesson_id,
        v_due_at
    FROM public.assignments
    WHERE id = p_assignment_id
      AND deleted_at IS NULL
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Завдання не знайдено або воно видалене.';
    END IF;

    IF v_assignment_offering_id <> v_enrollment_offering_id THEN
        RAISE EXCEPTION 'Завдання належить іншому проведенню курсу.';
    END IF;

    SELECT course_id, status, ends_on
    INTO v_course_id, v_offering_status, v_ends_on
    FROM public.course_offerings
    WHERE id = v_assignment_offering_id
    FOR SHARE;

    IF v_offering_status NOT IN ('open', 'ongoing')
       OR v_ends_on < CURRENT_DATE THEN
        RAISE EXCEPTION 'Здавання робіт для цього проведення закрите.';
    END IF;

    PERFORM 1
    FROM public.courses
    WHERE id = v_course_id
      AND deleted_at IS NULL
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Курс видалений.';
    END IF;

    IF v_lesson_id IS NOT NULL THEN
        PERFORM 1
        FROM public.lessons l
        JOIN public.modules m ON m.id = l.module_id
        WHERE l.id = v_lesson_id
          AND m.course_id = v_course_id
          AND l.deleted_at IS NULL
          AND m.deleted_at IS NULL
        FOR SHARE OF l, m;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Урок завдання недоступний.';
        END IF;
    END IF;

    IF v_due_at IS NOT NULL
       AND clock_timestamp() > v_due_at THEN
        RAISE EXCEPTION 'Строк здавання завдання минув.';
    END IF;

    IF COALESCE(btrim(p_answer_text), '') = ''
       AND COALESCE(btrim(p_attachment_url), '') = '' THEN
        RAISE EXCEPTION 'Потрібна текстова відповідь або посилання на файл.';
    END IF;

    SELECT COALESCE(MAX(attempt_no), 0) + 1
    INTO v_attempt_no
    FROM public.submissions
    WHERE assignment_id = p_assignment_id
      AND enrollment_id = p_enrollment_id;

    INSERT INTO public.submissions (
        assignment_id,
        enrollment_id,
        attempt_no,
        answer_text,
        attachment_url
    )
    VALUES (
        p_assignment_id,
        p_enrollment_id,
        v_attempt_no,
        p_answer_text,
        p_attachment_url
    )
    RETURNING id INTO p_submission_id;
END;
$$;

CREATE OR REPLACE VIEW public.v_submissions AS
SELECT
    s.id AS submission_id,
    s.assignment_id,
    a.title AS assignment_title,
    a.max_score,
    s.enrollment_id,
    e.student_id,
    u.first_name,
    u.last_name,
    a.offering_id,
    co.course_id,
    c.title AS course_title,
    s.attempt_no,
    s.answer_text,
    s.attachment_url,
    s.submitted_at
FROM public.submissions s
JOIN public.assignments a ON a.id = s.assignment_id
JOIN public.enrollments e ON e.id = s.enrollment_id
JOIN public.users u ON u.id = e.student_id
JOIN public.course_offerings co ON co.id = a.offering_id
JOIN public.courses c ON c.id = co.course_id
WHERE e.offering_id = a.offering_id;

BEGIN;

DO $$
DECLARE
    v_student_id bigint;
    v_enrollment_id bigint;
    v_assignment_id bigint;
    v_submission_id bigint;
BEGIN
    SELECT id INTO STRICT v_student_id
    FROM public.users
    WHERE email = 'student@example.invalid'
      AND deleted_at IS NULL;

    SELECT e.id, a.id
    INTO STRICT v_enrollment_id, v_assignment_id
    FROM public.enrollments e
    JOIN public.course_offerings co
        ON co.id = e.offering_id
    JOIN public.courses c
        ON c.id = co.course_id
    JOIN public.assignments a
        ON a.offering_id = co.id
    WHERE e.student_id = v_student_id
      AND co.name = 'Навчальна група 2026/27'
      AND c.title = 'Основи Java'
      AND a.title = 'Перша програма Java'
      AND a.deleted_at IS NULL
      AND c.deleted_at IS NULL;

    -- Повторний запуск цього прикладу не створить зайву спробу.
    IF NOT EXISTS (
        SELECT 1
        FROM public.submissions
        WHERE assignment_id = v_assignment_id
          AND enrollment_id = v_enrollment_id
    ) THEN
        CALL public.submit_assignment(
            v_assignment_id,
            v_enrollment_id,
            'String name = "Anna"; int age = 20; System.out.println(name + " " + age);',
            NULL,
            v_student_id,
            v_submission_id
        );
    END IF;
END;
$$;

COMMIT;


SELECT
    first_name,
    last_name,
    assignment_title,
    attempt_no,
    answer_text,
    submitted_at
FROM public.v_submissions
ORDER BY submission_id;

CREATE OR REPLACE PROCEDURE public.grade_submission(
    p_submission_id bigint,
    p_score numeric,
    p_feedback text,
    p_actor_id bigint
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_assignment_id bigint;
    v_offering_id bigint;
    v_course_id bigint;
    v_max_score numeric;
BEGIN
    PERFORM public.assert_active_role(
        p_actor_id,
        'INSTRUCTOR'
    );

    SELECT assignment_id
    INTO v_assignment_id
    FROM public.submissions
    WHERE id = p_submission_id
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Подану роботу не знайдено.';
    END IF;

    -- Блокування завдання також серіалізує
    -- одночасне оцінювання його робіт.
    SELECT offering_id, max_score
    INTO v_offering_id, v_max_score
    FROM public.assignments
    WHERE id = v_assignment_id
      AND deleted_at IS NULL
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Завдання видалене або не знайдене.';
    END IF;

    SELECT course_id
    INTO v_course_id
    FROM public.course_offerings
    WHERE id = v_offering_id
      AND status <> 'cancelled'
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Проведення курсу скасоване або не знайдене.';
    END IF;

    PERFORM 1
    FROM public.courses
    WHERE id = v_course_id
      AND deleted_at IS NULL
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Курс видалений.';
    END IF;

    PERFORM 1
    FROM public.offering_instructors
    WHERE offering_id = v_offering_id
      AND instructor_id = p_actor_id
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Викладач не призначений на це проведення.';
    END IF;

    IF p_score IS NULL
       OR p_score = 'NaN'::numeric
       OR p_score < 0
       OR p_score > v_max_score THEN
        RAISE EXCEPTION
            'Бал має бути в межах від 0 до %.',
            v_max_score;
    END IF;

    IF p_score <> round(p_score, 2) THEN
        RAISE EXCEPTION 'Бал може містити не більше двох знаків після коми.';
    END IF;

    INSERT INTO public.grades (
        submission_id,
        graded_by,
        score,
        feedback,
        updated_by
    )
    VALUES (
        p_submission_id,
        p_actor_id,
        p_score,
        p_feedback,
        p_actor_id
    )
    ON CONFLICT (submission_id)
    DO UPDATE SET
        graded_by = EXCLUDED.graded_by,
        score = EXCLUDED.score,
        feedback = EXCLUDED.feedback,
        graded_at = statement_timestamp(),
        updated_by = EXCLUDED.updated_by;
END;
$$;

CREATE OR REPLACE VIEW public.v_submission_results AS
SELECT
    s.submission_id,
    s.student_id,
    s.first_name,
    s.last_name,
    s.course_title,
    s.offering_id,
    s.assignment_id,
    s.assignment_title,
    s.attempt_no,
    s.submitted_at,
    s.max_score,
    g.score,
    g.feedback,
    g.graded_by,
    teacher.first_name AS teacher_first_name,
    teacher.last_name AS teacher_last_name,
    g.graded_at,
    g.updated_at,
    g.updated_by
FROM public.v_submissions s
LEFT JOIN public.grades g
    ON g.submission_id = s.submission_id
LEFT JOIN public.users teacher
    ON teacher.id = g.graded_by;

BEGIN;

DO $$
DECLARE
    v_teacher_id bigint;
    v_submission_id bigint;
BEGIN
    SELECT id INTO STRICT v_teacher_id
    FROM public.users
    WHERE email = 'teacher@example.invalid'
      AND deleted_at IS NULL;

    SELECT s.id
    INTO STRICT v_submission_id
    FROM public.submissions s
    JOIN public.enrollments e
        ON e.id = s.enrollment_id
    JOIN public.users u
        ON u.id = e.student_id
    JOIN public.assignments a
        ON a.id = s.assignment_id
    JOIN public.course_offerings co
        ON co.id = a.offering_id
    JOIN public.courses c
        ON c.id = co.course_id
    WHERE u.email = 'student@example.invalid'
      AND a.title = 'Перша програма Java'
      AND co.name = 'Навчальна група 2026/27'
      AND c.title = 'Основи Java'
      AND e.offering_id = a.offering_id
      AND s.attempt_no = 1;

    CALL public.grade_submission(
        v_submission_id,
        9,
        'Робота виконана правильно. Варто додати повний клас із методом main.',
        v_teacher_id
    );
END;
$$;

COMMIT;

SELECT
    first_name,
    last_name,
    assignment_title,
    attempt_no,
    score,
    max_score,
    teacher_first_name,
    teacher_last_name,
    feedback
FROM public.v_submission_results
ORDER BY submission_id;

CREATE OR REPLACE PROCEDURE public.complete_lesson(
    p_enrollment_id bigint,
    p_lesson_id bigint,
    p_actor_id bigint
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_student_id bigint;
    v_offering_id bigint;
    v_enrollment_status varchar(20);
    v_course_id bigint;
    v_offering_status varchar(20);
    v_ends_on date;
BEGIN
    PERFORM public.assert_active_role(p_actor_id, 'STUDENT');

    SELECT student_id, offering_id, status
    INTO v_student_id, v_offering_id, v_enrollment_status
    FROM public.enrollments
    WHERE id = p_enrollment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Запис студента на курс не знайдено.';
    END IF;

    IF v_student_id <> p_actor_id THEN
        RAISE EXCEPTION 'Не можна змінювати прогрес іншого студента.';
    END IF;

    IF v_enrollment_status <> 'active' THEN
        RAISE EXCEPTION 'Запис студента на курс неактивний.';
    END IF;

    SELECT course_id, status, ends_on
    INTO v_course_id, v_offering_status, v_ends_on
    FROM public.course_offerings
    WHERE id = v_offering_id
    FOR SHARE;

    IF v_offering_status NOT IN ('open', 'ongoing')
       OR v_ends_on < CURRENT_DATE THEN
        RAISE EXCEPTION 'Проходження цього проведення курсу закрите.';
    END IF;

    PERFORM 1
    FROM public.courses
    WHERE id = v_course_id
      AND deleted_at IS NULL
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Курс видалений.';
    END IF;

    PERFORM 1
    FROM public.lessons l
    JOIN public.modules m ON m.id = l.module_id
    WHERE l.id = p_lesson_id
      AND m.course_id = v_course_id
      AND l.deleted_at IS NULL
      AND m.deleted_at IS NULL
    FOR SHARE OF l, m;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Урок недоступний або належить іншому курсу.';
    END IF;

    INSERT INTO public.lesson_progress (
        enrollment_id,
        lesson_id
    )
    VALUES (
        p_enrollment_id,
        p_lesson_id
    )
    ON CONFLICT (enrollment_id, lesson_id) DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION public.calculate_course_progress(
    p_enrollment_id bigint
)
RETURNS numeric
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_course_id bigint;
    v_total bigint;
    v_completed bigint;
BEGIN
    SELECT co.course_id
    INTO v_course_id
    FROM public.enrollments e
    JOIN public.course_offerings co ON co.id = e.offering_id
    WHERE e.id = p_enrollment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Запис студента на курс не знайдено.';
    END IF;

    SELECT
        count(*),
        count(lp.lesson_id)
    INTO v_total, v_completed
    FROM public.v_active_lessons l
    LEFT JOIN public.lesson_progress lp
        ON lp.lesson_id = l.id
       AND lp.enrollment_id = p_enrollment_id
    WHERE l.course_id = v_course_id;

    IF v_total = 0 THEN
        RETURN 0;
    END IF;

    RETURN round(v_completed::numeric * 100 / v_total, 2);
END;
$$;

CREATE OR REPLACE VIEW public.v_student_progress AS
SELECT
    e.enrollment_id,
    e.student_id,
    e.first_name,
    e.last_name,
    e.course_id,
    e.course_title,
    e.offering_id,
    e.offering_name,
    e.status AS enrollment_status,
    public.calculate_course_progress(
        e.enrollment_id
    ) AS progress_percent
FROM public.v_course_enrollments e;

BEGIN;

DO $$
DECLARE
    v_student_id bigint;
    v_enrollment_id bigint;
    v_lesson_id bigint;
BEGIN
    SELECT id INTO STRICT v_student_id
    FROM public.users
    WHERE email = 'student@example.invalid'
      AND deleted_at IS NULL;

    SELECT e.id, l.id
    INTO STRICT v_enrollment_id, v_lesson_id
    FROM public.enrollments e
    JOIN public.course_offerings co
        ON co.id = e.offering_id
    JOIN public.courses c
        ON c.id = co.course_id
    JOIN public.modules m
        ON m.course_id = c.id
    JOIN public.lessons l
        ON l.module_id = m.id
    WHERE e.student_id = v_student_id
      AND co.name = 'Навчальна група 2026/27'
      AND c.title = 'Основи Java'
      AND m.position = 1
      AND l.position = 1
      AND c.deleted_at IS NULL
      AND m.deleted_at IS NULL
      AND l.deleted_at IS NULL;

    CALL public.complete_lesson(
        v_enrollment_id,
        v_lesson_id,
        v_student_id
    );
END;
$$;

COMMIT;

SELECT
    first_name,
    last_name,
    course_title,
    offering_name,
    progress_percent
FROM public.v_student_progress
ORDER BY enrollment_id;

CREATE OR REPLACE FUNCTION public.check_assignment_changes()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF (
        NEW.offering_id IS DISTINCT FROM OLD.offering_id
        OR NEW.lesson_id IS DISTINCT FROM OLD.lesson_id
    ) AND EXISTS (
        SELECT 1
        FROM public.submissions
        WHERE assignment_id = OLD.id
    ) THEN
        RAISE EXCEPTION
            'Не можна змінювати проведення або урок завдання, за яким уже є роботи.'
            USING ERRCODE = '23514';
    END IF;

    IF NEW.max_score IS DISTINCT FROM OLD.max_score
       AND EXISTS (
           SELECT 1
           FROM public.grades g
           JOIN public.submissions s
               ON s.id = g.submission_id
           WHERE s.assignment_id = OLD.id
             AND g.score > NEW.max_score
       ) THEN
        RAISE EXCEPTION
            'Максимальний бал не може бути нижчим за вже виставлені оцінки.'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_assignments_check_changes
BEFORE UPDATE OF max_score, offering_id, lesson_id
ON public.assignments
FOR EACH ROW
EXECUTE FUNCTION public.check_assignment_changes();

BEGIN;

CREATE TEMP TABLE assignment_check_result (
    result text
) ON COMMIT DROP;

DO $$
DECLARE
    v_assignment_id bigint;
    v_highest_score numeric;
BEGIN
    SELECT a.id, max(g.score)
    INTO v_assignment_id, v_highest_score
    FROM public.assignments a
    JOIN public.submissions s
        ON s.assignment_id = a.id
    JOIN public.grades g
        ON g.submission_id = s.id
    JOIN public.course_offerings co
        ON co.id = a.offering_id
    JOIN public.courses c
        ON c.id = co.course_id
    WHERE a.title = 'Перша програма Java'
      AND co.name = 'Навчальна група 2026/27'
      AND c.title = 'Основи Java'
    GROUP BY a.id
    HAVING max(g.score) > 0;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Для перевірки не знайдено завдання з додатною оцінкою.';
    END IF;

    BEGIN
        UPDATE public.assignments
        SET max_score = v_highest_score - 1
        WHERE id = v_assignment_id;

        INSERT INTO assignment_check_result
        VALUES ('ПОМИЛКА: некоректну зміну дозволено.');
    EXCEPTION
        WHEN check_violation THEN
            INSERT INTO assignment_check_result
            VALUES (
                'Перевірку пройдено: зменшення максимуму нижче оцінки заблоковано.'
            );
    END;
END;
$$;

SELECT result
FROM assignment_check_result;

ROLLBACK;

CREATE OR REPLACE FUNCTION public.calculate_course_score(
    p_enrollment_id bigint
)
RETURNS numeric
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_offering_id bigint;
    v_total_max numeric;
    v_total_score numeric;
BEGIN
    SELECT offering_id
    INTO v_offering_id
    FROM public.enrollments
    WHERE id = p_enrollment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Запис студента на курс не знайдено.';
    END IF;

    SELECT
        COALESCE(sum(a.max_score), 0),
        COALESCE(sum(best.score), 0)
    INTO v_total_max, v_total_score
    FROM public.v_active_assignments a
    LEFT JOIN (
        SELECT
            s.assignment_id,
            max(g.score) AS score
        FROM public.submissions s
        JOIN public.grades g ON g.submission_id = s.id
        WHERE s.enrollment_id = p_enrollment_id
        GROUP BY s.assignment_id
    ) best ON best.assignment_id = a.id
    WHERE a.offering_id = v_offering_id;

    IF v_total_max = 0 THEN
        RETURN 0;
    END IF;

    RETURN round(v_total_score * 100 / v_total_max, 2);
END;
$$;

CREATE OR REPLACE VIEW public.v_student_results AS
SELECT
    e.enrollment_id,
    e.student_id,
    e.first_name,
    e.last_name,
    e.course_id,
    e.course_title,
    e.offering_id,
    e.offering_name,
    e.status AS enrollment_status,
    public.calculate_course_progress(
        e.enrollment_id
    ) AS progress_percent,
    public.calculate_course_score(
        e.enrollment_id
    ) AS score_percent
FROM public.v_course_enrollments e;

SELECT
    first_name,
    last_name,
    course_title,
    progress_percent,
    score_percent
FROM public.v_student_results
ORDER BY enrollment_id;

SELECT
    e.enrollment_id,
    a.id AS assignment_id,
    a.lesson_id,
    e.student_id
FROM public.v_course_enrollments e
JOIN public.v_active_assignments a
    ON a.offering_id = e.offering_id
WHERE e.first_name = 'Anna'
  AND e.last_name = 'Melnyk'
  AND a.title = 'Перша програма Java';
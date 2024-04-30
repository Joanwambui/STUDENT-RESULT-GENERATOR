WITH cte_marks AS (
    SELECT
        student_id,
        s.name,
        column1 AS subject_code,
        column2 AS marks
    FROM
        student_marks sm
    CROSS APPLY (
        VALUES 
            ('subject1', subject1),
            ('subject2', subject2),
            ('subject3', subject3),
            ('subject4', subject4),
            ('subject5', subject5),
            ('subject6', subject6)
    ) AS subjects (column1, column2)
    JOIN students s ON s.roll_no = sm.student_id
    WHERE
        column2 IS NOT NULL
),
cte_sub AS (
    SELECT
        subject_code,
        subject_name,
        pass_marks
    FROM (
        SELECT
            column_name AS subject_code,
            ROW_NUMBER() OVER (ORDER BY ordinal_position) AS rn
        FROM
            information_schema.columns 
        WHERE
            table_name = 'student_marks' 
            AND column_name LIKE 'subject%'
    ) a
    JOIN (
        SELECT
            ROW_NUMBER() OVER (ORDER BY id) AS rn,
            name AS subject_name,
            pass_marks
        FROM
            subjects
    ) b ON a.rn = b.rn
),
cte_agg AS (
    SELECT
        student_id,
        name,
        ROUND(AVG(marks), 2) AS percentage_marks,
        STRING_AGG(CASE WHEN marks >= pass_marks THEN NULL ELSE subject_name END, ', ') AS failed_subjects
    FROM
        cte_marks cm
    JOIN cte_sub cs ON cs.subject_code = cm.subject_code
    GROUP BY
        student_id,
        name
)

SELECT
    *,
    CASE
        WHEN failed_subjects IS NOT NULL THEN 'Fail'
        WHEN percentage_marks >= 70 THEN 'First Class'
        WHEN percentage_marks BETWEEN 50 AND 70 THEN 'Second Class'
        WHEN percentage_marks < 50 THEN 'Third Class'
    END AS Result
FROM
    cte_agg;

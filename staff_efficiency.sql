/* 
  Staff Efficiency Tracker - SQL Implementation
  Author: Wyatt Brereton
  Purpose: Automate staff rental performance tracking using functions, triggers, and stored procedures
*/

/* Step 1: Create Detailed and Summary Tables */

CREATE TABLE IF NOT EXISTS rental_details (
    staff_id SMALLINT,
    staff_name VARCHAR(50),
    store_id SMALLINT,
    rental_id INT,
    rental_date DATE
);

CREATE TABLE IF NOT EXISTS staff_summary (
    staff_id SMALLINT,
    staff_name VARCHAR(50),
    store_id SMALLINT,
    total_rentals INT,
    workload_tier CHAR(6)
);

/* Step 2: Define Workload Tier Function */

CREATE OR REPLACE FUNCTION assign_workload_tier(rental_count INT)
RETURNS CHAR(6) AS $$
BEGIN
    IF rental_count > 1000 THEN
        RETURN 'High';
    ELSIF rental_count BETWEEN 501 AND 1000 THEN
        RETURN 'Medium';
    ELSE
        RETURN 'Low';
    END IF;
END;
$$ LANGUAGE plpgsql;

/* Step 3: Create Trigger Function to Update Summary Table */

CREATE OR REPLACE FUNCTION update_staff_summary()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM staff_summary;

    INSERT INTO staff_summary (staff_id, staff_name, store_id, total_rentals, workload_tier)
    SELECT
        staff_id,
        MIN(staff_name),
        store_id,
        COUNT(*) AS total_rentals,
        assign_workload_tier(COUNT(*)::INT)
    FROM rental_details
    GROUP BY staff_id, store_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

/* Step 4: Create Trigger to Run After Insert on rental_details */

CREATE TRIGGER trg_update_staff_summary
AFTER INSERT ON rental_details
FOR EACH STATEMENT
EXECUTE FUNCTION update_staff_summary();

/* Step 5: Create Stored Procedure to Refresh All Data */

CREATE OR REPLACE PROCEDURE refresh_staff_data()
LANGUAGE plpgsql AS $$
BEGIN
    TRUNCATE TABLE rental_details;
    TRUNCATE TABLE staff_summary;

    INSERT INTO rental_details
    SELECT
        s.staff_id,
        CONCAT(s.first_name, ' ', s.last_name),
        s.store_id,
        r.rental_id,
        r.rental_date
    FROM rental r
    JOIN staff s ON r.staff_id = s.staff_id;
END;
$$;

/* Step 6: Optional Execution Steps */

-- To refresh the data manually
-- CALL refresh_staff_data();

-- To view the performance summary
-- SELECT * FROM staff_summary ORDER BY total_rentals DESC;

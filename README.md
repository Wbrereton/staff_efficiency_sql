# staff_efficiency_sql
A PostgreSQL project using triggers and stored procedures to track and categorize staff performance.
# staff_efficiency_sql
A PostgreSQL project using triggers and stored procedures to track and categorize staff performance.
# Staff Efficiency Tracker — SQL Trigger Project

## Overview
This project implements an automated staff performance tracking system using PostgreSQL. It calculates rental processing volume per staff member and classifies their workload into performance tiers — High, Medium, or Low — using SQL triggers, functions, and stored procedures.

The system supports store managers, HR teams, and regional leadership by keeping a refreshed summary of staff performance, helping optimize scheduling, training, and operational decisions.

---

## Tech Stack

| Component       | Tool/Language  |
|-----------------|----------------|
| Database        | PostgreSQL     |
| Procedural Logic| PL/pgSQL       |
| UI Tool         | pgAdmin        |
| Automation Tool | pgAgent        |

---

## Features

- **Dynamic Trigger**: Automatically updates the performance summary after inserts to the detailed table.
- **Stored Procedure**: Refreshes raw and summary data on demand.
- **Custom Tier Logic**: Classifies staff as High, Medium, or Low based on rental volume.
- **Business Driven Structure**: Designed for real world retail analytics.
- **Scalable**: Easily extendable to other datasets or performance KPIs.

---

## Tables

### `rental_details` (Raw Data)

| Field       | Type        |
|-------------|-------------|
| staff_id    | SMALLINT    |
| staff_name  | VARCHAR(50) |
| store_id    | SMALLINT    |
| rental_id   | INT         |
| rental_date | DATE        |

### `staff_summary` (Performance Summary)

| Field          | Type        |
|----------------|-------------|
| staff_id       | SMALLINT    |
| staff_name     | VARCHAR(50) |
| store_id       | SMALLINT    |
| total_rentals  | INT         |
| workload_tier  | CHAR(6)     |

---

## Key Logic and SQL Code

### 1. Assign Workload Tier Function

```sql
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
CREATE TRIGGER trg_update_staff_summary
AFTER INSERT ON rental_details
FOR EACH STATEMENT
EXECUTE FUNCTION update_staff_summary();
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
-- Refresh the data manually (if needed)
CALL refresh_staff_data();

-- View the current staff performance summary
SELECT * FROM staff_summary
ORDER BY total_rentals DESC;
---

## Sample Output

Below is a sample of what the `staff_summary` table looks like after inserting data into `rental_details`. This table is automatically refreshed by the trigger and shows total rentals processed per staff member, categorized into workload tiers.

| staff_id | staff_name       | store_id | total_rentals | workload_tier |
|----------|------------------|----------|----------------|----------------|
| 1        | Alex Rodriguez   | 1        | 1,240          | High           |
| 2        | Sarah Mitchell   | 2        |   962          | Medium         |
| 3        | Emily Carter     | 1        |   489          | Low            |
| 4        | Jordan Kim       | 2        | 1,102          | High           |
| 5        | Daniel Freeman   | 1        |   701          | Medium         |


---

## Business Value

This system supports better business decision-making by:

- **Enabling real-time insights**: Updates summary metrics automatically after each data insert using a trigger.
- **Enhancing staff oversight**: Quickly identifies high and low performers across store locations.
- **Supporting training & scheduling**: Helps managers allocate resources, identify training opportunities, and maintain fairness.
- **Driving operational efficiency**: Provides actionable metrics during daily huddles, weekly meetings, or HR performance reviews.

It’s a scalable, low-maintenance solution that can plug directly into a BI dashboard or serve as a backend to HR decision models.

---

## Automation Plan

To keep `staff_summary` refreshed regularly without manual intervention:

- **Use pgAgent** — a job scheduling extension built for PostgreSQL.
- **Schedule the procedure `refresh_staff_data()`** to run daily (e.g., 6 AM), or at whatever frequency aligns with business needs.
- **Setup via pgAdmin GUI**:
  - Create a job under pgAgent
  - Use a simple SQL step: `CALL refresh_staff_data();`
  - Set recurrence interval (daily, hourly, etc.)
- Optional: Add email notifications or logging to verify each job run.

---

## Author

**Wyatt Brereton**  
Bachelor of Science – Data Analytics  
Western Governors University  
[GitHub Profile](https://github.com/Wbrereton) *(https://github.com/Wbrereton)*

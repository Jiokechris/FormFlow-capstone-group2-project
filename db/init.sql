-- Runs automatically on first container start via docker-entrypoint-initdb.d
-- (MySQL only executes this on an empty data volume — it will NOT re-run on existing data)
--USE school;

CREATE TABLE IF NOT EXISTS student (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(40) NOT NULL,
    roll_number INT NOT NULL,
    class VARCHAR(16) NOT NULL
);

CREATE TABLE IF NOT EXISTS teacher (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(40) NOT NULL,
    subject VARCHAR(40) NOT NULL,
    class VARCHAR(16) NOT NULL
);

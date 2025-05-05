-- Create sensor_data table for all sensor readings
CREATE TABLE IF NOT EXISTS sensor_data (
    id INT PRIMARY KEY AUTO_INCREMENT,
    temperature FLOAT,
    humidity FLOAT,
    air_quality FLOAT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create ocr_results table for water meter readings
CREATE TABLE IF NOT EXISTS ocr_results (
    id INT PRIMARY KEY AUTO_INCREMENT,
    ocr_text VARCHAR(50) NOT NULL,
    water_bill FLOAT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Crear la base de datos
CREATE DATABASE IF NOT EXISTS control_telefonia;
USE control_telefonia;

-- Tabla de tipos de llamada
CREATE TABLE tipos_llamada (
    id_tipo INT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    costo_por_minuto DECIMAL(10,2) NOT NULL
);

-- Tabla de líneas telefónicas
CREATE TABLE lineas_telefonicas (
    id_linea INT PRIMARY KEY AUTO_INCREMENT,
    numero_telefono VARCHAR(20) UNIQUE NOT NULL,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de llamadas
CREATE TABLE llamadas (
    id_llamada INT PRIMARY KEY AUTO_INCREMENT,
    id_linea INT,
    id_tipo INT,
    duracion_minutos DECIMAL(10,2) NOT NULL,
    costo_total DECIMAL(10,2),
    fecha_llamada DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_linea) REFERENCES lineas_telefonicas(id_linea),
    FOREIGN KEY (id_tipo) REFERENCES tipos_llamada(id_tipo)
);

-- Tabla para totales (evita cálculos pesados en consultas frecuentes)
CREATE TABLE totales_linea (
    id_linea INT PRIMARY KEY,
    total_llamadas INT DEFAULT 0,
    total_minutos DECIMAL(10,2) DEFAULT 0,
    total_costo DECIMAL(10,2) DEFAULT 0,
    FOREIGN KEY (id_linea) REFERENCES lineas_telefonicas(id_linea)
);

-- Insertar tipos de llamada
INSERT INTO tipos_llamada (id_tipo, nombre, costo_por_minuto) VALUES
(1, 'Local', 35.00),
(2, 'Larga Distancia', 380.00),
(3, 'Celular', 999.00);

-- Trigger para calcular costo total antes de insertar
DELIMITER //
CREATE TRIGGER tr_calcular_costo_llamada
BEFORE INSERT ON llamadas
FOR EACH ROW
BEGIN
    DECLARE costo_minuto DECIMAL(10,2);
    
    SELECT costo_por_minuto INTO costo_minuto
    FROM tipos_llamada
    WHERE id_tipo = NEW.id_tipo;
    
    SET NEW.costo_total = NEW.duracion_minutos * costo_minuto;
END//

-- Trigger para actualizar totales después de insertar
CREATE TRIGGER tr_actualizar_totales
AFTER INSERT ON llamadas
FOR EACH ROW
BEGIN
    UPDATE totales_linea 
    SET total_llamadas = total_llamadas + 1,
        total_minutos = total_minutos + NEW.duracion_minutos,
        total_costo = total_costo + NEW.costo_total
    WHERE id_linea = NEW.id_linea;
END//

DELIMITER ;

-- Procedimientos almacenados
DELIMITER //

-- Procedimiento para agregar llamada
CREATE PROCEDURE sp_agregar_llamada(
    IN p_linea INT,
    IN p_tipo INT,
    IN p_duracion DECIMAL(10,2)
)
BEGIN
    INSERT INTO llamadas (id_linea, id_tipo, duracion_minutos)
    VALUES (p_linea, p_tipo, p_duracion);
    
    SELECT 'Llamada registrada exitosamente' AS mensaje;
END//

-- Procedimiento para obtener información de línea
CREATE PROCEDURE sp_info_linea(
    IN p_linea INT
)
BEGIN
    SELECT 
        l.numero_telefono,
        t.total_llamadas,
        t.total_minutos,
        t.total_costo
    FROM lineas_telefonicas l
    JOIN totales_linea t ON l.id_linea = t.id_linea
    WHERE l.id_linea = p_linea;
END//

-- Procedimiento para obtener información consolidada
CREATE PROCEDURE sp_info_consolidada()
BEGIN
    SELECT 
        SUM(total_llamadas) as total_llamadas,
        SUM(total_minutos) as total_minutos,
        SUM(total_costo) as total_costo,
        CASE 
            WHEN SUM(total_minutos) > 0 
            THEN SUM(total_costo)/SUM(total_minutos)
            ELSE 0 
        END as costo_promedio_minuto
    FROM totales_linea;
END//

-- Procedimiento para reiniciar líneas
CREATE PROCEDURE sp_reiniciar_lineas()
BEGIN
    START TRANSACTION;
    
    DELETE
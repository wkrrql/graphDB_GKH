--  Вариант 62. Графовая БД: ЖКХ — Дома, Котельные, Магистрали

USE master;
GO

IF DB_ID('GKH_Graph') IS NOT NULL
BEGIN
    ALTER DATABASE GKH_Graph SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GKH_Graph;
END
GO

CREATE DATABASE GKH_Graph;
GO

USE GKH_Graph;
GO

-- 1. Таблицы узлов (4 типа)
CREATE TABLE dbo.House (
    house_id INT NOT NULL,
    address NVARCHAR(200) NOT NULL,
    floors TINYINT NOT NULL,
    apartments SMALLINT NOT NULL,
    year_built SMALLINT NOT NULL,
    heating_type NVARCHAR(50) NOT NULL,
    status NVARCHAR(30) NOT NULL
) AS NODE;
GO

CREATE TABLE dbo.Boilerhouse (
    boiler_id INT NOT NULL,
    name NVARCHAR(100) NOT NULL,
    address NVARCHAR(200) NOT NULL,
    fuel_type NVARCHAR(50) NOT NULL,
    capacity_gcalh DECIMAL(8,2) NOT NULL,
    year_built SMALLINT NOT NULL,
    status NVARCHAR(30) NOT NULL
) AS NODE;
GO

CREATE TABLE dbo.Pipeline (
    pipe_id INT NOT NULL,
    name NVARCHAR(100) NOT NULL,
    diameter_mm SMALLINT NOT NULL,
    length_m INT NOT NULL,
    material NVARCHAR(50) NOT NULL,
    year_laid SMALLINT NOT NULL,
    status NVARCHAR(30) NOT NULL
) AS NODE;
GO

CREATE TABLE dbo.District (
    district_id INT NOT NULL,
    name NVARCHAR(100) NOT NULL,
    population INT NOT NULL,
    area_km2 DECIMAL(6,2) NOT NULL
) AS NODE;
GO

-- 2. Таблицы рёбер (3 связи)
CREATE TABLE dbo.Supplies (
    supply_date DATE NOT NULL,
    flow_gcalh DECIMAL(8,2) NOT NULL,
    pressure_bar DECIMAL(5,2) NOT NULL,
    status NVARCHAR(30) NOT NULL
) AS EDGE;
GO
ALTER TABLE dbo.Supplies ADD CONSTRAINT EC_Supplies CONNECTION (Boilerhouse TO Pipeline);
GO

CREATE TABLE dbo.ConnectedTo (
    connection_date DATE NOT NULL,
    heat_load_gcalh DECIMAL(6,3) NOT NULL,
    meter_installed BIT NOT NULL DEFAULT 1,
    last_inspection DATE NULL
) AS EDGE;
GO
ALTER TABLE dbo.ConnectedTo ADD CONSTRAINT EC_ConnectedTo CONNECTION (Pipeline TO House);
GO

CREATE TABLE dbo.LocatedIn (
    reg_date DATE NOT NULL,
    note NVARCHAR(200) NULL
) AS EDGE;
GO
ALTER TABLE dbo.LocatedIn ADD CONSTRAINT EC_LocatedIn CONNECTION (House TO District);
GO

-- 3. Данные узлов
INSERT INTO dbo.District (district_id, name, population, area_km2) VALUES
(1, N'Центральный', 45000, 12.50),
(2, N'Северный', 38000, 18.30),
(3, N'Южный', 52000, 21.70),
(4, N'Восточный', 29000, 15.40),
(5, N'Западный', 41000, 19.80);
GO

INSERT INTO dbo.Boilerhouse (boiler_id, name, address, fuel_type, capacity_gcalh, year_built, status) VALUES
(1, N'Котельная №1 Центральная', N'ул. Заводская, 1', N'газ', 85.00, 1985, N'работает'),
(2, N'Котельная №2 Северная', N'ул. Полярная, 12', N'газ', 60.50, 1992, N'работает'),
(3, N'Котельная №3 Южная', N'ул. Степная, 5', N'газ', 72.00, 1988, N'работает'),
(4, N'Котельная №4 Восточная', N'пр. Восточный, 44', N'уголь', 40.00, 1979, N'на ТО'),
(5, N'Котельная №5 Западная', N'ул. Лесная, 3', N'газ', 55.00, 1995, N'работает');
GO

INSERT INTO dbo.Pipeline (pipe_id, name, diameter_mm, length_m, material, year_laid, status) VALUES
(1, N'Магистраль М-1 Центр', 300, 4200, N'сталь', 1990, N'в работе'),
(2, N'Магистраль М-2 Север', 250, 3800, N'сталь', 1993, N'в работе'),
(3, N'Магистраль М-3 Юг', 300, 5100, N'сталь', 1989, N'в работе'),
(4, N'Магистраль М-4 Восток', 200, 2900, N'сталь', 1980, N'аварийный'),
(5, N'Магистраль М-5 Запад', 250, 4500, N'ПЭ', 2005, N'в работе'),
(6, N'Распределитель Р-1', 100, 900, N'ПП', 2012, N'в работе');
GO

INSERT INTO dbo.House (house_id, address, floors, apartments, year_built, heating_type, status) VALUES
(1, N'ул. Ленина, 5', 9, 72, 1985, N'централизованное', N'эксплуатируется'),
(2, N'ул. Ленина, 7', 9, 72, 1986, N'централизованное', N'эксплуатируется'),
(3, N'пр. Мира, 12', 12, 96, 1992, N'централизованное', N'эксплуатируется'),
(4, N'ул. Садовая, 3', 5, 40, 1975, N'централизованное', N'аварийный'),
(5, N'ул. Полярная, 8', 9, 72, 1988, N'централизованное', N'эксплуатируется'),
(6, N'ул. Степная, 10', 16, 160, 2005, N'централизованное', N'эксплуатируется');
GO

-- 4. Данные рёбер
INSERT INTO dbo.Supplies ($from_id, $to_id, supply_date, flow_gcalh, pressure_bar, status) VALUES
((SELECT $node_id FROM dbo.Boilerhouse WHERE boiler_id=1),
 (SELECT $node_id FROM dbo.Pipeline WHERE pipe_id=1),
 '2023-09-01', 70.00, 6.5, N'активно'),
((SELECT $node_id FROM dbo.Boilerhouse WHERE boiler_id=2),
 (SELECT $node_id FROM dbo.Pipeline WHERE pipe_id=2),
 '2022-09-01', 55.00, 6.0, N'активно'),
((SELECT $node_id FROM dbo.Boilerhouse WHERE boiler_id=3),
 (SELECT $node_id FROM dbo.Pipeline WHERE pipe_id=3),
 '2021-10-01', 65.00, 6.2, N'активно'),
((SELECT $node_id FROM dbo.Boilerhouse WHERE boiler_id=4),
 (SELECT $node_id FROM dbo.Pipeline WHERE pipe_id=4),
 '2020-09-01', 35.00, 5.0, N'приостановлено'),
((SELECT $node_id FROM dbo.Boilerhouse WHERE boiler_id=5),
 (SELECT $node_id FROM dbo.Pipeline WHERE pipe_id=5),
 '2023-09-01', 50.00, 6.3, N'активно'),
((SELECT $node_id FROM dbo.Boilerhouse WHERE boiler_id=5),
 (SELECT $node_id FROM dbo.Pipeline WHERE pipe_id=6),
 '2023-09-01', 8.00, 5.7, N'активно');
GO

INSERT INTO dbo.ConnectedTo ($from_id, $to_id, connection_date, heat_load_gcalh, meter_installed, last_inspection) VALUES
((SELECT $node_id FROM dbo.Pipeline WHERE pipe_id=1),
 (SELECT $node_id FROM dbo.House WHERE house_id=1),
 '1990-01-01', 0.185, 1, '2024-03-15'),
((SELECT $node_id FROM dbo.Pipeline WHERE pipe_id=1),
 (SELECT $node_id FROM dbo.House WHERE house_id=2),
 '1990-01-01', 0.185, 1, '2024-03-15'),
((SELECT $node_id FROM dbo.Pipeline WHERE pipe_id=2),
 (SELECT $node_id FROM dbo.House WHERE house_id=5),
 '1988-01-01', 0.185, 1, '2024-01-10'),
((SELECT $node_id FROM dbo.Pipeline WHERE pipe_id=3),
 (SELECT $node_id FROM dbo.House WHERE house_id=6),
 '2005-01-01', 0.420, 1, '2024-02-05'),
((SELECT $node_id FROM dbo.Pipeline WHERE pipe_id=3),
 (SELECT $node_id FROM dbo.House WHERE house_id=4),
 '1975-01-01', 0.110, 0, '2022-05-01'),
((SELECT $node_id FROM dbo.Pipeline WHERE pipe_id=6),
 (SELECT $node_id FROM dbo.House WHERE house_id=3),
 '2012-01-01', 0.240, 1, '2024-04-10');
GO

INSERT INTO dbo.LocatedIn ($from_id, $to_id, reg_date, note) VALUES
((SELECT $node_id FROM dbo.House WHERE house_id=1), (SELECT $node_id FROM dbo.District WHERE district_id=1), '1985-01-01', NULL),
((SELECT $node_id FROM dbo.House WHERE house_id=2), (SELECT $node_id FROM dbo.District WHERE district_id=1), '1986-01-01', NULL),
((SELECT $node_id FROM dbo.House WHERE house_id=3), (SELECT $node_id FROM dbo.District WHERE district_id=1), '1992-01-01', NULL),
((SELECT $node_id FROM dbo.House WHERE house_id=4), (SELECT $node_id FROM dbo.District WHERE district_id=3), '1975-01-01', N'Аварийный'),
((SELECT $node_id FROM dbo.House WHERE house_id=5), (SELECT $node_id FROM dbo.District WHERE district_id=2), '1988-01-01', NULL),
((SELECT $node_id FROM dbo.House WHERE house_id=6), (SELECT $node_id FROM dbo.District WHERE district_id=3), '2005-01-01', NULL);
GO

-- 5. Запросы MATCH
-- Запрос 1
SELECT
    b.name AS Котельная,
    p.name AS Трубопровод,
    h.address AS Адрес_дома,
    ct.heat_load_gcalh AS Нагрузка_Гкал_ч,
    s.flow_gcalh AS Поток_от_котельной
FROM
    dbo.Boilerhouse AS b,
    dbo.Supplies AS s,
    dbo.Pipeline AS p,
    dbo.ConnectedTo AS ct,
    dbo.House AS h
WHERE
    MATCH(b-(s)->p-(ct)->h)
    AND b.boiler_id = 1
ORDER BY p.name, h.address;
GO

-- Запрос 2
SELECT
    b.name AS Котельная,
    b.capacity_gcalh AS Мощность,
    p.name AS Трубопровод,
    h.address AS Дом,
    d.name AS Район
FROM
    dbo.Boilerhouse AS b,
    dbo.Supplies AS s,
    dbo.Pipeline AS p,
    dbo.ConnectedTo AS ct,
    dbo.House AS h,
    dbo.LocatedIn AS li,
    dbo.District AS d
WHERE
    MATCH(b-(s)->p-(ct)->h-(li)->d)
    AND b.fuel_type = N'газ'
ORDER BY b.name, h.address;
GO

-- Запрос 3
SELECT
    p.name AS Трубопровод,
    p.status AS Статус_трубы,
    h.address AS Дом,
    h.status AS Статус_дома,
    d.name AS Район
FROM
    dbo.Pipeline AS p,
    dbo.ConnectedTo AS ct,
    dbo.House AS h,
    dbo.LocatedIn AS li,
    dbo.District AS d
WHERE
    MATCH(p-(ct)->h-(li)->d)
    AND (p.status <> N'в работе' OR h.status <> N'эксплуатируется')
ORDER BY h.status DESC;
GO

-- Запрос 4
SELECT
    b.name AS Котельная,
    p.name AS Трубопровод,
    h.address AS Дом,
    d.name AS Район,
    s.flow_gcalh AS Поток,
    ct.heat_load_gcalh AS Нагрузка
FROM
    dbo.Boilerhouse AS b,
    dbo.Supplies AS s,
    dbo.Pipeline AS p,
    dbo.ConnectedTo AS ct,
    dbo.House AS h,
    dbo.LocatedIn AS li,
    dbo.District AS d
WHERE
    MATCH(b-(s)->p-(ct)->h-(li)->d)
    AND s.status = N'активно'
ORDER BY b.name, h.address;
GO

-- Запрос 5
SELECT
    b.name AS Котельная,
    p.name AS Трубопровод,
    h.address AS Дом,
    d.name AS Район
FROM
    dbo.Boilerhouse AS b,
    dbo.Supplies AS s,
    dbo.Pipeline AS p,
    dbo.ConnectedTo AS ct,
    dbo.House AS h,
    dbo.LocatedIn AS li,
    dbo.District AS d
WHERE
    MATCH(b-(s)->p-(ct)->h-(li)->d)
    AND d.name = N'Центральный'
ORDER BY h.address;
GO

-- 6. Универсальный граф и SHORTEST_PATH
CREATE TABLE dbo.GKH_Node (
    obj_id INT NOT NULL,
    obj_type NVARCHAR(30) NOT NULL,
    obj_name NVARCHAR(200) NOT NULL
) AS NODE;
GO

CREATE TABLE dbo.GKH_Edge (
    rel_type NVARCHAR(50) NOT NULL,
    weight DECIMAL(8,2) NOT NULL DEFAULT 1
) AS EDGE;
GO

INSERT INTO dbo.GKH_Node (obj_id, obj_type, obj_name)
SELECT boiler_id, N'boiler', name FROM dbo.Boilerhouse UNION ALL
SELECT pipe_id, N'pipe', name FROM dbo.Pipeline UNION ALL
SELECT house_id, N'house', address FROM dbo.House UNION ALL
SELECT district_id, N'district', name FROM dbo.District;
GO

INSERT INTO dbo.GKH_Edge ($from_id, $to_id, rel_type, weight)
SELECT n1.$node_id, n2.$node_id, N'Supplies', s.flow_gcalh
FROM dbo.Supplies s
JOIN dbo.Boilerhouse b ON b.$node_id = s.$from_id
JOIN dbo.Pipeline p ON p.$node_id = s.$to_id
JOIN dbo.GKH_Node n1 ON n1.obj_id = b.boiler_id AND n1.obj_type = N'boiler'
JOIN dbo.GKH_Node n2 ON n2.obj_id = p.pipe_id AND n2.obj_type = N'pipe';

INSERT INTO dbo.GKH_Edge ($from_id, $to_id, rel_type, weight)
SELECT n1.$node_id, n2.$node_id, N'ConnectedTo', 1
FROM dbo.ConnectedTo ct
JOIN dbo.Pipeline p ON p.$node_id = ct.$from_id
JOIN dbo.House h ON h.$node_id = ct.$to_id
JOIN dbo.GKH_Node n1 ON n1.obj_id = p.pipe_id AND n1.obj_type = N'pipe'
JOIN dbo.GKH_Node n2 ON n2.obj_id = h.house_id AND n2.obj_type = N'house';

INSERT INTO dbo.GKH_Edge ($from_id, $to_id, rel_type, weight)
SELECT n1.$node_id, n2.$node_id, N'LocatedIn', 1
FROM dbo.LocatedIn li
JOIN dbo.House h ON h.$node_id = li.$from_id
JOIN dbo.District d ON d.$node_id = li.$to_id
JOIN dbo.GKH_Node n1 ON n1.obj_id = h.house_id AND n1.obj_type = N'house'
JOIN dbo.GKH_Node n2 ON n2.obj_id = d.district_id AND n2.obj_type = N'district';
GO

-- SP-1: шаблон "+"
SELECT
    src.obj_name AS Котельная,
    LAST_VALUE(dst.obj_name) WITHIN GROUP (GRAPH PATH) AS Дом,
    COUNT(dst.obj_id) WITHIN GROUP (GRAPH PATH) AS Длина_пути,
    STRING_AGG(dst.obj_name, ' -> ') WITHIN GROUP (GRAPH PATH) AS Промежуточные_узлы
FROM
    dbo.GKH_Node AS src,
    dbo.GKH_Edge FOR PATH AS e,
    dbo.GKH_Node FOR PATH AS dst
WHERE
    MATCH(SHORTEST_PATH(src(-(e)->dst)+))
    AND src.obj_id = 1
    AND src.obj_type = N'boiler'
ORDER BY Длина_пути, Дом;
GO

-- SP-2: шаблон "{1,5}"
SELECT
    src.obj_name AS Котельная,
    LAST_VALUE(dst.obj_name) WITHIN GROUP (GRAPH PATH) AS Конечный_объект,
    COUNT(dst.obj_id) WITHIN GROUP (GRAPH PATH) AS Шагов,
    STRING_AGG(dst.obj_name, ' -> ') WITHIN GROUP (GRAPH PATH) AS Полный_путь
FROM
    dbo.GKH_Node AS src,
    dbo.GKH_Edge FOR PATH AS e,
    dbo.GKH_Node FOR PATH AS dst
WHERE
    MATCH(SHORTEST_PATH(src(-(e)->dst){1,5}))
    AND src.obj_type = N'boiler'
ORDER BY src.obj_name, Шагов;
GO

-- SP-3: шаблон "{1,4}"
SELECT
    src.obj_name AS Котельная,
    LAST_VALUE(dst.obj_name) WITHIN GROUP (GRAPH PATH) AS Район,
    COUNT(dst.obj_id) WITHIN GROUP (GRAPH PATH) AS Шагов,
    STRING_AGG(dst.obj_name, ' -> ') WITHIN GROUP (GRAPH PATH) AS Маршрут
FROM
    dbo.GKH_Node AS src,
    dbo.GKH_Edge FOR PATH AS e,
    dbo.GKH_Node FOR PATH AS dst
WHERE
    MATCH(SHORTEST_PATH(src(-(e)->dst){1,4}))
    AND src.obj_type = N'boiler'
ORDER BY src.obj_name, Шагов;
GO

PRINT N'БД GKH_Graph создана и заполнена успешно.';
GO
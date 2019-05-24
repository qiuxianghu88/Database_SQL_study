-- 1、创建数据库，加载数据
CREATE DATABASE kh1;
CREATE USER kh1_u WITH SUPERUSER;
\c kh1 kh1_u
	-- 创建数据库及用户，并设置用户为超级管理员


-- 2、加载数据（自选数据，或者提供数据），存储为Table对象
CREATE TABLE data(
 	update_time date,
 	id text,
 	title text,
 	price numeric,
 	sale_count int,
 	comment_count int,
 	店名 text
 	);
	-- 创建表格
\COPY data FROM '/Users/qiuxianghu/Desktop/体验课资料_双十一淘宝美妆数据.csv' WITH CSV HEADER;
	-- 加载数据


-- 3、选取该数据中1-2个字段，并创建新的表格对象
CREATE TABLE data1 AS SELECT id,title,price FROM data;


-- 4、查看数据的缺失值，如果有数据缺失，则填充缺失值：数值字段填充0，字符字段填充“缺失数据”
\d data
SELECT * FROM data WHERE update_time IS NULL; 
	-- 查看日期字段是否有缺失值
SELECT * FROM data WHERE id IS NULL OR title IS NULL OR 店名 IS NULL; 
	-- 查看字符字段是否有缺失值
SELECT * FROM data WHERE price IS NULL OR sale_count IS NULL OR comment_count IS NULL; 
	-- 查看数值字段是否有缺失值

UPDATE data SET price = 0 WHERE price IS NULL;  
UPDATE data SET sale_count = 0 WHERE sale_count IS NULL;
UPDATE data SET comment_count = 0 WHERE comment_count IS NULL;
	-- 填充缺失值


-- 5、移动数据：创建新的表格，将导入的源数据的一半数据量移动到新数据中
CREATE TABLE data2 (LIKE data); 
	-- 创建空表data2
WITH t AS (
	DELETE FROM data WHERE update_time IN ('2016-11-5','2016-11-6','2016-11-7','2016-11-8')   
	RETURNING * )                        
	INSERT INTO data2(SELECT * FROM t); 
	-- 移动数据
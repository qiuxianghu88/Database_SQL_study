-- 1、创建数据库，加载数据
CREATE DATABASE kh2;
\c kh2
	-- 创建数据库

CREATE TABLE data1(姓 varchar(10),户籍地城市编号 text CHECK(LENGTH(户籍地城市编号)=6));  
	-- 由于数据原因，户籍城市编号中包含字符，所以这里为text
	-- 通过添加条件约束，排除长度不为6的情况
CREATE TABLE data2 (LIKE data1);
CREATE TABLE cities(
	行政编码 int,
	省 varchar(10),市 varchar(10),区县 text,
	lng numeric,lat numeric);
	-- 创建表格

\COPY data1 FROM '/Users/qiuxianghu/Desktop/data01.csv' WITH CSV HEADER ENCODING 'utf8';
\COPY data2 FROM '/Users/qiuxianghu/Desktop/data02.csv' WITH CSV HEADER ENCODING 'utf8';
\COPY cities FROM '/Users/qiuxianghu/Desktop/中国行政代码对照表.csv' WITH CSV HEADER ENCODING 'utf8';
	-- 加载数据


-- 2、数据整理及合并
SELECT * FROM data1 
	WHERE SUBSTRING(户籍地城市编号,1,1) NOT IN ('1','2','3','4','5','6','7','8','9','0') OR
	SUBSTRING(户籍地城市编号,2,1) NOT IN ('1','2','3','4','5','6','7','8','9','0') OR
	SUBSTRING(户籍地城市编号,3,1) NOT IN ('1','2','3','4','5','6','7','8','9','0') OR
	SUBSTRING(户籍地城市编号,4,1) NOT IN ('1','2','3','4','5','6','7','8','9','0') OR
	SUBSTRING(户籍地城市编号,5,1) NOT IN ('1','2','3','4','5','6','7','8','9','0') OR
	SUBSTRING(户籍地城市编号,6,1) NOT IN ('1','2','3','4','5','6','7','8','9','0');
	-- 查看错误数据

DELETE FROM data1 
	WHERE SUBSTRING(户籍地城市编号,1,1) NOT IN ('1','2','3','4','5','6','7','8','9','0') OR
	SUBSTRING(户籍地城市编号,2,1) NOT IN ('1','2','3','4','5','6','7','8','9','0') OR
	SUBSTRING(户籍地城市编号,3,1) NOT IN ('1','2','3','4','5','6','7','8','9','0') OR
	SUBSTRING(户籍地城市编号,4,1) NOT IN ('1','2','3','4','5','6','7','8','9','0') OR
	SUBSTRING(户籍地城市编号,5,1) NOT IN ('1','2','3','4','5','6','7','8','9','0') OR
	SUBSTRING(户籍地城市编号,6,1) NOT IN ('1','2','3','4','5','6','7','8','9','0');
DELETE FROM data2 
	WHERE SUBSTRING(户籍地城市编号,1,1) NOT IN ('1','2','3','4','5','6','7','8','9','0') OR
	SUBSTRING(户籍地城市编号,2,1) NOT IN ('1','2','3','4','5','6','7','8','9','0') OR
	SUBSTRING(户籍地城市编号,3,1) NOT IN ('1','2','3','4','5','6','7','8','9','0') OR
	SUBSTRING(户籍地城市编号,4,1) NOT IN ('1','2','3','4','5','6','7','8','9','0') OR
	SUBSTRING(户籍地城市编号,5,1) NOT IN ('1','2','3','4','5','6','7','8','9','0') OR
	SUBSTRING(户籍地城市编号,6,1) NOT IN ('1','2','3','4','5','6','7','8','9','0');
	-- 删除错误数据

ALTER TABLE data1 DROP CONSTRAINT data1_户籍地城市编号_check;
ALTER TABLE data1 ALTER COLUMN 户籍地城市编号 TYPE int USING(户籍地城市编号::int);
ALTER TABLE data2 ALTER COLUMN 户籍地城市编号 TYPE int USING(户籍地城市编号::int);
	-- 修改数据格式，注意这里需要删除data1的CHECK约束
	-- 这里需要用到USING(column_name::integer)

CREATE TABLE data AS
	SELECT * FROM data1 UNION ALL SELECT * FROM data2;
	-- 合并data1和data2

CREATE TABLE result_data AS
	SELECT d.姓,d.户籍地城市编号,c.省,c.市,c.区县,c.lng,c.lat
		FROM data d INNER JOIN cities c
		ON d.户籍地城市编号 = c.行政编码;
	-- 连接数据，得到结果数据

SELECT * FROM result_data LIMIT 10;
	-- 查看数据


-- 3、将数据按照“姓”做统计，找到姓氏数量最多的TOP20
SELECT 姓,COUNT(姓),
	CAST(COUNT(姓)AS numeric)/(SELECT COUNT(姓) FROM result_data) AS 姓氏占比
	FROM result_data GROUP BY 姓 ORDER BY COUNT(姓) DESC LIMIT 20;
	-- 注意计算占比这里，需要将分子（或分母）转换成浮点型
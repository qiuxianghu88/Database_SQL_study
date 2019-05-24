-- 1、创建数据库，加载数据
CREATE DATABASE kh3;
\c kh3
	-- 创建数据库

CREATE TABLE data(
 	update_time date,
 	id text,title text,
 	price numeric,sale_count int,comment_count int,店名 text);
	-- 创建表格
\COPY data FROM '/Users/qiuxianghu/Desktop/tb_data.csv' WITH CSV HEADER;

	-- 加载数据
ALTER TABLE data RENAME COLUMN id TO 商品id;
ALTER TABLE data RENAME COLUMN update_time TO 日期;
ALTER TABLE data RENAME COLUMN title TO 商品名称;
ALTER TABLE data RENAME COLUMN price TO 价格;
ALTER TABLE data RENAME COLUMN sale_count TO 销售量;
ALTER TABLE data RENAME COLUMN comment_count TO 评价数量;
ALTER TABLE data RENAME COLUMN 店名 TO 品牌名称;
	-- 修改列名
	
SELECT COUNT(商品id)  AS 数据总量 FROM data;
WITH t AS (SELECT DISTINCT 商品id FROM data) SELECT COUNT(商品id) AS 产品id总量 FROM t;
SELECT 品牌名称,COUNT(商品id) AS 不同品牌的数据量 FROM data GROUP BY 品牌名称 ORDER BY COUNT(商品id) DESC;
	-- 查看数据总量，产品id总量，以及不同品牌的数据量


-- 2、双十一打折情况解析
	-- 按照商品销售节奏分类，我们可以将商品分为7类
	-- A. 11.11前后及当天都在售 → 一直在售
	-- B. 11.11之后停止销售 → 双十一后停止销售
	-- C. 11.11开始销售并当天不停止 → 双十一当天上架并持续在售
	-- D. 11.11开始销售且当天停止 → 仅双十一当天有售
	-- E. 11.5 - 11.10 → 双十一前停止销售
	-- F. 11.12开始销售 → 双十一后上架
	-- G. 仅11.11当天停止销售 → 仅双十一当天停止销售
CREATE TABLE data_11 AS 
	SELECT 商品id FROM data WHERE 日期 = '2016-11-11';  
ALTER TABLE data_11 ADD 是否参与活动 boolean;
UPDATE data_11 SET 是否参与活动 = True;
	-- 找到参与双十一当天活动的产品id，并添加“是否参与活动”字段
CREATE TABLE q1_1 AS
	SELECT 商品id,MAX(日期),MIN(日期) FROM data GROUP BY 商品id;
	-- 按照id分组汇总，得到每个产品销售的开始/结束日期
CREATE TABLE q1_2 AS 
	SELECT d1.商品id, d1.max,d1.min,d2.是否参与活动
		FROM q1_1 d1 FULL OUTER JOIN data_11 d2 ON d1.商品id = d2.商品id;
UPDATE q1_2 SET 是否参与活动 = False WHERE 是否参与活动 IS NULL;
	-- 数据连接，并更新“是否参与活动”字段 → 未参与活动的值为false

ALTER TABLE q1_2 ADD 销售类型 varchar(10);
UPDATE q1_2 SET 销售类型 = 'A'
	WHERE 是否参与活动 = True AND max > '2016-11-11' AND min < '2016-11-11';
	-- 筛选A类
UPDATE q1_2 SET 销售类型 = 'B'
	WHERE 是否参与活动 = True AND max = '2016-11-11' AND min < '2016-11-11';
	-- 筛选B类
UPDATE q1_2 SET 销售类型 = 'C'
	WHERE 是否参与活动 = True AND max > '2016-11-11' AND min = '2016-11-11';
	-- 筛选C类
UPDATE q1_2 SET 销售类型 = 'D'
	WHERE 是否参与活动 = True AND max = '2016-11-11' AND min = '2016-11-11';
	-- 筛选D类
UPDATE q1_2 SET 销售类型 = 'E'
	WHERE 是否参与活动 = False AND max < '2016-11-11';
	-- 筛选E类
UPDATE q1_2 SET 销售类型 = 'F'
	WHERE 是否参与活动 = False AND min > '2016-11-11';
	-- 筛选F类
UPDATE q1_2 SET 销售类型 = 'G'
	WHERE 是否参与活动 = False AND min < '2016-11-11' AND max > '2016-11-11';
	-- 筛选G类

SELECT 销售类型,COUNT(销售类型),
	CAST(COUNT(销售类型)AS numeric)/(SELECT COUNT(销售类型) FROM q1_2) AS 类型占比
	FROM q1_2 GROUP BY 销售类型 ORDER BY COUNT(销售类型) DESC;
	-- 查看不同销售类型的占比

ALTER TABLE data ADD 是否参与活动 boolean;
ALTER TABLE data ADD 销售类型 varchar(10);
UPDATE data SET 是否参与活动 = q1_2.是否参与活动 FROM q1_2 WHERE data.商品id = q1_2.商品id;
UPDATE data SET 销售类型 = q1_2.销售类型 FROM q1_2 WHERE data.商品id = q1_2.商品id;
	-- 将得到的数据字段“是否参与活动”和“销售类型”，连接到原始数据上


-- 3、哪些商品真的在打折？真正打折的商品折扣率是多少？
CREATE TABLE q2_1 AS 
	SELECT DISTINCT 商品id,价格 FROM data ORDER BY 商品id;
	-- 按照id和price查询唯一值
CREATE TABLE q2_2 AS
	SELECT 商品id,MAX(价格),MIN(价格) FROM q2_1 GROUP BY 商品id HAVING COUNT(商品id) > 1;
	-- 筛选出打折商品id → 只要price唯一值出现次数超过1则有价格变动
	-- HAVING 是用于筛选group by以后count大于1的，count的结果不会出现在表格的字段中

ALTER TABLE q2_2 ADD 是否打折 boolean DEFAULT True;
ALTER TABLE q2_2 ADD 折扣率 numeric;
UPDATE q2_2 SET 折扣率 = min/max;
	-- 计算出打折商品的折扣率

ALTER TABLE data ADD 是否打折 boolean DEFAULT False;
ALTER TABLE data ADD 折扣率 numeric DEFAULT 1.0;
UPDATE data SET 是否打折 = q2_2.是否打折 FROM q2_2 WHERE data.商品id = q2_2.商品id;
UPDATE data SET 折扣率 = q2_2.折扣率 FROM q2_2 WHERE data.商品id = q2_2.商品id;
	-- 数据连接，源数据添加“是否打折”、“折扣率”信息

WITH t AS (SELECT DISTINCT 商品id,是否打折 FROM data) 
	SELECT CAST((SELECT COUNT(是否打折) FROM t WHERE 是否打折 = True) AS numeric)/(SELECT COUNT(是否打折) FROM t) 
		AS 真正打折的商品数量占比;
	-- 查看真正打折的商品数量占比

WITH t AS (SELECT DISTINCT 商品id,折扣率,品牌名称 FROM data) 
	SELECT 品牌名称,AVG(折扣率) AS 平均打折力度 FROM t GROUP BY 品牌名称 ORDER BY AVG(折扣率);
	-- 查看不同品牌的平均打折力度


-- 4、商家营销套路挖掘
CREATE TABLE q3_1 AS
	SELECT DISTINCT 品牌名称,商品id,是否打折,折扣率 FROM data;
	-- 去重数据

CREATE TABLE q3_2 AS 
	SELECT 品牌名称,AVG(折扣率),COUNT(商品id) FROM q3_1 GROUP BY 品牌名称;
	-- 汇总数据，得到不同品牌的平均打折力度、商品数量

CREATE TABLE q3_3 AS 
	SELECT 品牌名称,COUNT(商品id) FROM q3_1 WHERE 是否打折 = True GROUP BY 品牌名称;
	-- 计算不同品牌实际打折商品的数量

ALTER TABLE q3_2 ADD 打折商品数 int DEFAULT 0;
UPDATE q3_2 SET 打折商品数 = q3_3.count FROM q3_3 WHERE q3_2.品牌名称 = q3_3.品牌名称;
	-- 数据连接，将打折商品数字段存到q3_2中

ALTER TABLE q3_2 RENAME COLUMN avg TO 平均打折力度;
ALTER TABLE q3_2 RENAME COLUMN count TO 商品总数;
	-- 修改列明

\COPY data TO '/Users/qiuxianghu/Desktop/结果数据.csv' WITH CSV HEADER;
\COPY q3_2 TO '/Users/qiuxianghu/Desktop/打折套路挖掘结果.csv' WITH CSV HEADER;
	-- 导出
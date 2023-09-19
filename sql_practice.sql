-- 2.		-- (10%) Import file excel dataset Chợ tốt
				-- (10%) Tạo Table CHOTOT_2 như sau:
				-- Region là kiểu dữ liệu ký tự (hỗ trợ Unicode) và tối đa 150 ký tự
				-- Income là kiểu dữ liệu ký tự (không hỗ trợ Unicode) và tối đa 50 ký tự
CREATE TABLE CHOTOT_2
(
	[Region] NVARCHAR(150),
	[Income] VARCHAR(50)
)
GO
INSERT INTO CHOTOT_2 VALUES
('Dong Nam Bo','High'),
('Quang Nam Da Nang','Medium'),
('Hai Phong - Nam Dinh - Thai Binh','Low'),
('Tay Nam Bo','Low'),
('Nam Trung Bo','Medium'),
('Tay Nguyen','Medium'),
('Dong Bac','Medium'),
('Tay Bac','Medium'),
('Ha Noi','High'),
('TP HCM','High')
GO

-------------------------------------------------------------------------------------------------------------------------
-- 3.		-- Ở cột Region, update các giá trị Đông Nam Bộ và DNB thành Dong Nam Bo để đảm bảo consistent
UPDATE dbo.[data$]
SET Region = 'Dong Nam Bo'
WHERE region = N'Đông Nam Bộ' or region = 'DNB'

-------------------------------------------------------------------------------------------------------------------------
-- 4.		-- Có bao nhiêu Contact_Private_Sellers theo từng Platform
SELECT platform
				, COUNT(Contact_Private_Sellers) AS so_luong
FROM dbo.[data$]
GROUP BY platform

-------------------------------------------------------------------------------------------------------------------------
-- 5.		-- Từ table CHOTOT và CHOTOT2, tính tổng Contact_Pro_Sellers theo từng Regions với điều kiện sau:
				-- Chỉ lấy Regions có Income High hoặc Medium
SELECT a.Region
				, SUM(a.Contact_Pro_Sellers) AS sum_
FROM dbo.[data$] a
INNER JOIN dbo.CHOTOT_2 b
			ON b.Region = a.Region
WHERE b.Income <> 'low'
GROUP BY a.Region

 				-- Platform không bao gồm Chotot Desktop
 SELECT  a.region
				, SUM(Contact_Pro_Sellers) AS sum_
FROM dbo.[data$] a
INNER JOIN dbo.CHOTOT_2 b
			ON a.Region = b.Region
 WHERE platform <> 'Chotot Desktop'
GROUP BY a.Region

				-- Từ ngày 1 đến ngày 15 hằng tháng hoặc từ ngày 25 hằng tháng trở đi
 SELECT  a.region
				, SUM(Contact_Pro_Sellers) AS sum_
FROM dbo.[data$] a
INNER JOIN dbo.CHOTOT_2 b
			ON a.Region = b.Region
WHERE (DAY(date) BETWEEN 1 AND 15 OR DAY(date) >25)
GROUP BY a.region

-------------------------------------------------------------------------------------------------------------------------
-- What are the top 3 regions with highest number of private sellers contacts by each platform? ​
SELECT TOP 3 region
				, sum(Contact_Private_Sellers) AS sum_pri
FROM dbo.[data$]
GROUP BY Region
ORDER BY sum_pri DESC

----------------------------------------------------------------
-- What are the top 3 regions that prefer buying from the Pro sellers? ​
SELECT  TOP 3 region
				, CASE WHEN sum(Contact_Pro_Sellers) - sum(Contact_Private_Sellers) < 0 THEN sum(Contact_Pro_Sellers) 
				END AS diff
FROM dbo.[data$]
GROUP BY region
ORDER BY diff DESC

-- For each day, what are the region with highest number of seller?​
WITH tam AS (
							SELECT Region
											, Date
											, SUM(Contact_Private_Sellers) + SUM(Contact_Pro_Sellers) AS sum_
							FROM dbo.[data$]
							GROUP BY date, region )
, tam2 AS (
					SELECT DATE
									, MAX(sum_) AS highest
					FROM tam
					GROUP BY date )
SELECT a.Region
				, a.Date
				, b.highest
FROM tam a
INNER JOIN tam2 b
ON b.Date = a.Date AND b.highest = a.sum_

-------------------------------------------------------------------------------------------------------------------------
-- (5%) For each month, please make 4 columns:​
				-- Total sellers of Hanoi​
				-- Total sellers of TP HCM
				-- If total sellers of Ha Noi >= 45% HCM, then write ‘HN has more than 45% sellers of HCM’
				-- else write ‘HN has less than 45% sellers of HCM’, name the column HN situation
WITH hcm AS (
SELECT MONTH(date) AS month_
				, SUM(Contact_Private_Sellers) + SUM(Contact_Pro_Sellers) AS total_hcm
FROM dbo.[data$]
WHERE region = 'TP HCM'
GROUP BY MONTH(date) )

, hanoi AS (
SELECT MONTH(date) AS month_
				, SUM(Contact_Private_Sellers) + SUM(Contact_Pro_Sellers) AS total_hanoi
FROM dbo.[data$]
WHERE region = 'Hanoi'
GROUP BY MONTH(date) )

SELECT total_hcm
				, total_hanoi
				, CASE WHEN b.total_hanoi >= 0.45 *  a.total_hcm THEN 'HN has more than 45% sellers of HCM' END AS Conclusion
				, CASE WHEN b.total_hanoi < 0.45 *  a.total_hcm THEN 'HN has less than 45% sellers of HCM' END AS Conclusion2
FROM hcm a
INNER JOIN hanoi b
			on a.month_ = b.month_
ORDER BY a.month_ ASC
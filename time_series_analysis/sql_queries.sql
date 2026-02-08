-- 남성 의류업과 여성 의류업의 월간 매출과 12개월 이동 평균 매출

-- 월간 매출
SELECT a.kind_of_business 
,a.sales_month
,a.sales
,avg(b.sales) as moving_avg
,count(b.sales) as records_count
FROM retail_sales a
JOIN retail_sales b on a.kind_of_business = b.kind_of_business 
 and b.sales_month between a.sales_month - interval '11 months' 
 and a.sales_month
 and b.kind_of_business in ('Women''s clothing stores', 'Men''s clothing stores')
WHERE a.kind_of_business in ('Women''s clothing stores', 'Men''s clothing stores')
and a.sales_month >= '1993-01-01'
GROUP BY 1,2,3
ORDER BY 1,2
;

-- 12개월 이동 평균 매출
SELECT *
FROM (SELECT kind_of_business
,sales_month
,sales
,avg(sales) over (partition by kind_of_business
ORDER BY sales_month rows between 11 preceding and current row) as moving_avg
,count(sales) over (partition by kind_of_business
ORDER BY sales_month rows between 11 preceding and current row) as records_count
FROM retail_sales
WHERE kind_of_business in ('Women''s clothing stores', 'Men''s clothing stores')
)
WHERE sales_month >= '1993-01-01'

-- 최근 여성 의류업의 월간 매출과 누적 매출(YTD)
SELECT sales_month
,sales
,sum(sales) over (partition by date_part('year',sales_month) order by sales_month) as sales_ytd
FROM retail_sales
WHERE kind_of_business = 'Women''s clothing stores'
;

-- 여성 의류업과 남성 의류업의 연간 매출
SELECT sales_month
,kind_of_business
,sales
FROM retail_sales
WHERE kind_of_business in ('Men''s clothing stores','Women''s clothing stores')
ORDER BY 1,2
;

--여성 의류업과 남성 의류업 매출의 절대적 차이&상대적 차이(비율)

-- 절대적 차이
SELECT date_part('year',sales_month) as sales_year
,sum(case when kind_of_business = 'Women''s clothing stores'
          then sales end)
-
sum(case when kind_of_business = 'Men''s clothing stores'
          then sales end)
as womens_minus_mens
FROM retail_sales
WHERE kind_of_business in ('Men''s clothing stores'
,'Women''s clothing stores')
and sales_month <= '2019-12-01'
GROUP BY 1
ORDER BY 1
;

-- 상대적 차이
SELECT sales_year
,womens_sales*1.0 / mens_sales as womens_times_of_mens
FROM
(
    SELECT date_part('year',sales_month) as sales_year
    ,sum(case when kind_of_business = 'Women''s clothing stores'
              then sales
              end) as womens_sales
    ,sum(case when kind_of_business = 'Men''s clothing stores'
              then sales
              end) as mens_sales
    FROM retail_sales
    WHERE kind_of_business in ('Men''s clothing stores'
    ,'Women''s clothing stores')
    and sales_month <= '2019-12-01'
    GROUP BY 1
) a
ORDER BY 1
;

-- 여성 의류업과 남성 의류업의 월간 매출 비율
SELECT sales_month, kind_of_business, sales
,sum(sales) over (partition by sales_month) as total_sales
,sales * 100.0 / sum(sales) over (partition by sales_month) as pct_total
FROM retail_sales
WHERE kind_of_business in ('Men''s clothing stores'
,'Women''s clothing stores')
ORDER BY 1,2
;

-- 여성 의류업과 남성 의류업의 연간 매출 대비 월간 매출 비율(2019년)
SELECT sales_month, kind_of_business, sales
,sum(sales) over (partition by date_part('year',sales_month)
                               ,kind_of_business
                               ) as yearly_sales
,sales * 100.0 /
 sum(sales) over (partition by date_part('year',sales_month)
                               ,kind_of_business
                               ) as pct_yearly
FROM retail_sales
WHERE kind_of_business in ('Men''s clothing stores'
 ,'Women''s clothing stores')
ORDER BY 1,2
;

-- 1992년을 기준으로 인덱싱된 여성 의류업과 남성 의류업의 매출 변화
SELECT sales_year, kind_of_business, sales
,(sales*1.0 / first_value(sales) over (partition by kind_of_business order by sales_year) - 1) * 100 as pct_from_index
FROM
(
    SELECT date_part('year',sales_month) as sales_year
    ,kind_of_business
    ,sum(sales) as sales
    FROM retail_sales
    WHERE kind_of_business in ('Men''s clothing stores','Women''s clothing stores')  and sales_month <= '2019-12-31'
    GROUP BY 1,2
) a
ORDER BY 1,2
;

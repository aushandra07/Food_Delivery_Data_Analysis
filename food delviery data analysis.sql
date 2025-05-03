---1. Find top 3 outlets by cuisine type without using limit or top function
with
  top_outlet as (
    select
      Cuisine,
      Restaurant_id,
      count(restaurant_id) as no_of_orders,
      DENSE_RANK() over (
        partition by
          cuisine
        order by
          count(restaurant_id) desc
      ) as rnk
    from
      orders
    group by
      Cuisine,
      Restaurant_id
  )
select
  cuisine,
  restaurant_id,
  no_of_orders
from
  top_outlet
where
  rnk <= 3
order by
  Cuisine

---2. Find the daily new customer count from the launch date(everyday how many new customers  are we acquiring)
with
  new_customer as (
    select
      cast(Placed_at as date) as dt,
      Customer_code,
      ROW_NUMBER() over (
        partition by
          customer_code
        order by
          cast(Placed_at as date)
      ) as rep
    from
      orders
  )
select
  dt as date,
  count(customer_code) as new_customer
from
  new_customer
where
  rep = 1
group by
  dt
order by
  dt

---OR---
with
  cte as (
    select
      Customer_code,
      cast(min(placed_At) as date) as dt
    from
      orders
    group by
      Customer_code
  )
select
  dt as date,
  count(Customer_code) as new_customers
from
  cte
group by
  dt
order by
  dt


---3. Count of all users who were acquired  in jan2025 and only placed one order in jan  and did not place any other order
with
  cnt as (
    select
      month (cast(min(placed_At) as date)) as month,
      Customer_code,
      count(*) as orrder
    from
      orders
    where
      year (placed_At) = 2025
    group by
      Customer_code
  )
select
  (Customer_code)
from
  cnt
where
  month = 1
  and orrder = 1


---4. List of all the customers with no order in the last 7 days but were acquired one month ago with their first  order on promo
select
  a.Customer_code,
  max(a.placed_At) as latest_order_date,
  min(b.placed_At) as first_order_Date,
  b.Promo_code_Name as promocode_for_firstorder
from
  orders as a
  join orders as b on a.Customer_code = b.Customer_code
where
  b.Promo_code_Name is not null
group by
  a.Customer_code,
  b.Promo_code_Name
having
  max(a.placed_At) < DATEADD (day, -7, GETDATE ())
  and min(b.placed_At) < DATEADD (month, -1, GETDATE ())


---5. Growth team is planning to create a trigger that will target customers after their every 3rd order  with a personalized  communication  and they have 
-- asked  you to write a query for this
select Customer_code, Placed_at 
from (select Customer_code, Placed_at,ROW_NUMBER() over(partition by Customer_code order by placed_at) as order_number
from orders
) a
where order_number%3 = 0
and cast(placed_At as date) = cast (getdate() as date) 
--this is for when we are running the query at the end of the day and therfore will give the 3,6,9th order for the day so that we dont send the same ocmmunication again and again 


---6. List of cusomters who placed more than 1 order and all their orders on a promo only
select
  Customer_code,
  count(*) as ordercount,
  count(Promo_code_Name) as promocount
from
  orders
group by
  Customer_code
having
  COUNT(*) > 1
  and count(*) = count(Promo_code_Name)


---7. What percent of customers were organically acquired in jan2025(placed their first order without promo code)
with
  ct as (
    select
      *,
      ROW_NUMBER() over (
        partition by
          Customer_code
        order by
          placed_At
      ) as rn
    from
      orders
    where
      MONTH (placed_at) = 1
      and year (placed_At) = 2025
  )
select
  count(
    case
      when rn = 1
      and promo_code_name is null then customer_code
    end
  ) * 100.0 / count(distinct Customer_code)
from
  ct
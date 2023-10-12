--Q1: Who is the most senior most employee based on job title?
select * from employee
order by levels desc
limit 1

--Q2: which countries have the most invoices?
select billing_country, count(invoice_id) 
from invoice
group by billing_country
order by count(invoice_id) desc

--Q3: what are the top three values of total invoice?
select total from invoice
order by total desc
limit 3

--Q4: which city has the best customer?
--write a query that returns one city that has the highest sum of invoice totals.
--Return both the city name and sum of all invoice totals.
select c.city, sum(i.total) as invoice_total
from customer c
inner join invoice i
on i.customer_id = c.customer_id
group by city
order by sum(total) desc

--Q5: who is the best customer? Write a query who has spent the most money.
select c.first_name, c.last_name, sum(i.total) as invoice_total
from customer c
inner join invoice i 
on i.customer_id = c.customer_id
group by 1,2 
order by sum(total) desc
limit 1

--Q6: Write query to return the email,first name, last name and genre of all rock music listeners.
--Return your list ordered alphabetically by email starting with A.
select distinct first_name, last_name, email
from customer c
join invoice i on c.customer_id = i.customer_id
join invoice_line il on i.invoice_id = il.invoice_id
where track_id in(
    select track_id from track t
    join genre g on t.genre_id = g.genre_id
    where g.name like 'Rock'
)
order by email;

--Q7: Write a query that returns the artist name and total track count of the top 10 rock bands.
select artist.name ,artist.artist_id, count(artist.artist_id) as total_no_of_songs
from artist
join album on artist.artist_id = album.artist_id
join track on album.album_id = track.album_id
join genre on track.genre_id = genre.genre_id
where genre.name like 'Rock'
group by artist.artist_id
order by total_no_of_songs desc 
limit 10;

--Q8: Return all the track names that have a song length longer than the average song length. 
--Return the name and milliseconds for each track. Order by the song length with the longest songs listed first.
select name, milliseconds
from track
where milliseconds > (
select avg(milliseconds) as avg_track_length
from track)
order by milliseconds desc;

--Q9: Find how much amount spent by each customer on top artist? write a query to return customer name, artist name and total spent. 
--for amount spent, we are going to use  quantity*unit price in invoiceline instead of total from invoice table
--using CTE. Finding best selling artist
with best_selling_artist as(
    select artist.artist_id, artist.name as artist_name, 
    sum(invoice_line.unit_price * invoice_line.quantity) as total_sales
    from invoice_line
    join track on invoice_line.track_id = track.track_id
    join album on track.album_id = album.album_id
    join artist on album.artist_id = artist.artist_id
	group by 1
    order by total_sales desc
	limit 1
)

select customer.customer_id, customer.first_name, customer.last_name, bsa.artist_name,
sum(invoice_line.unit_price * invoice_line.quantity) as total_sales
from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
join track on invoice_line.track_id = track.track_id
join album on track.album_id = album.album_id
join best_selling_artist bsa on album.artist_id = bsa.artist_id
group by 1,2,3,4
order by 5 desc;

--Q10: We want to find out the most popular music genre for each country.
--we determine the most popular genre as the genre with highest amount of purchases. Write a 
--query that returns each country along with the top genre. For counrties where the maximum number of purchases is shared return all genres.

with popular_genre as 
(
  select count(invoice_line.quantity) as purchases, customer.country, genre.name, genre.genre_id,
  row_number() over(partition by customer.country order by count(invoice_line.quantity) desc) as row_no
  from invoice_line
  join invoice on invoice.invoice_id = invoice_line.invoice_id
  join customer on invoice.customer_id = customer.customer_id
  join track on track.track_id = invoice_line.track_id
  join genre on genre.genre_id = track.genre_id
  group by 2,3,4
  order by 2 asc, 1 desc
)
select * from popular_genre where row_no <= 1
--used row number() because we wanted one highest value for each country

--Q11: Write a query that determines the customer that has spent the most on music for each country. Write a query that returns
--the country along with the top customer and how much they spent. For countries where the top amount 
--spent is shared, provide all customers who spent this amount.

with recursive 
  customer_country as(
      select c.customer_id, c.first_name, c.last_name, i.billing_Country, sum(total) as total_spending
      from customer c
      join invoice i on c.customer_id = i.customer_id
      group by 1,2,3,4
      order by 1,5 desc),
	  
  country_max_spend as(
      select billing_country, max(total_spending) as max_spending
	  from customer_country
	  group by 1)

select cuc.billing_country, cuc.total_spending, cuc.first_name, cuc.last_name,cuc.customer_id
from customer_country cuc
join country_max_spend cms
on cuc.billing_country = cms.billing_country
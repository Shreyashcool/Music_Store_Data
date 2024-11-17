use Music_Store_databse

Q1.who is the senior most employee based on job title ?

select TOP 1 employee_id,last_name,first_name,levels,title
from employee
order by levels desc 

Q2. Which countries have the most invoices ?

select COUNT(*) as c , billing_country
from invoice
group by billing_country
order by c desc

Q3. What are top 3 values of total invoice ?

select TOP 3 total
from invoice
order by total desc 

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

select SUM(total) as invoice_total, billing_city
from invoice
group by billing_city
order by invoice_total desc


/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

select top 1 customer.customer_id,customer.first_name,customer.last_name ,sum(invoice.total) as total
from customer
JOIN invoice on customer.customer_id = invoice.customer_id
group by customer.customer_id, customer.first_name,customer.last_name
order by total desc

/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

select distinct first_name,last_name, email 
from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_line_id
where track_id IN(
       select track_id from track
	   join genre on track.genre_id = genre.genre_id
	   where genre.name like 'Rock'
)
order by email;

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

select top 10 artist.artist_id, artist.name, count(artist.artist_id) as number_of_songs
from track 
join album on album.album_id = track.album_id
join artist on artist.artist_id = album.artist_id
join genre on genre.genre_id = track.genre_id
where genre.name like 'Rock'
group by artist.artist_id,artist.name
order by number_of_songs desc


/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */
----using sub-query---
select name,milliseconds
from track
where milliseconds	>(
                       select AVG(milliseconds) as avg_track_length
					   from track)
order by milliseconds desc;


/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

with best_selling_artist as (
     select top 1 artist.artist_id as artist_id, artist.name as artist_name, 
	 sum(invoice_line.unit_price * invoice_line.quantity) as total_sales 
from invoice_line
join track on track.track_id = invoice_line.track_id
join album on album.album_id = track.album_id 
join artist on artist.artist_id = album.artist_id
group by artist.artist_id,artist.name
order by total_sales desc
)
select c.customer_id, c.first_name, c.last_name, bsa.artist_name,
     sum(il.unit_price * il.quantity) as amount_spent
from invoice i
join customer c on c.customer_id = i.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
join album alb on alb.album_id = t.album_id
join best_selling_artist bsa  on bsa.artist_id = alb.artist_id 
GROUP BY c.customer_id, c.first_name, c.last_name, bsa.artist_name
ORDER BY amount_spent DESC;


/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

with popular_genre AS 
(
   select count(invoice_line.quantity) as purchases, customer.country, genre.name, genre.genre_id,
   ROW_NUMBER() over(partition by customer.country order by count(invoice_line.quantity) desc) as RowNo
   from invoice_line
   join invoice on invoice.invoice_id = invoice_line.invoice_id
   join customer on customer.customer_id = invoice.customer_id
   join track on track.track_id = invoice_line.track_id
   join genre on genre.genre_id = track.genre_id
   GROUP BY customer.country, genre.name, genre.genre_id
  -- order by 2 asc, 1 desc 
   )

   SELECT * 
FROM popular_genre
WHERE RowNo = 1;


/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

with customer_with_country as (
              select customer.customer_id,customer.first_name,customer.last_name,
			  sum(total) as total_spending,
			  ROW_NUMBER() over(partition by billing_country order by sum(total) desc) as RowNo
			  from invoice 
			  join customer on customer.customer_id = invoice.customer_id
			  group by customer.customer_id,first_name,last_name,billing_country)
			  ---order by billing_country desc)
select * from customer_with_country where RowNo <=1
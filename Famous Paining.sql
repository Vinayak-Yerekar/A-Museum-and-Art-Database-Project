/*1. Paintings which are not displayed on any museums?*/

select * 
from work
where museum_id is null

/*2.Are there museuems without any paintings?*/

select * from museum
where museum_id not in (select museum_id from work)

/*3. Paintings with more sale price than their regular price? */

select * from product_size
where sale_price > regular_price

/*4. Painting's sale price is less than 50% of its regular price*/

select * from product_size
where sale_price < (regular_price/2);

/*5. canvas size with high costs*/

with Expensive_canvas as
(
select p.size_id, 
		c.label, 
		p.sale_price, 
		DENSE_RANK() over(order by sale_price desc) as rnk
from	product_size p
join	canvas_size c on p.size_id = c.size_id
)
select * from Expensive_canvas
where rnk = 1


/*6. Top 10 most famous painting subject. */

with famous_painting as
(
select  s.subject, 
		COUNT(s.subject) no_of_painting, 
		DENSE_RANK() over(order by COUNT(s.subject) desc) rnk 
from	work w
join	subject s on w.work_id = s.work_id
group by s.subject
)

select * from famous_painting
where rnk <= 10;

/*7. Museums which are open on both Sunday and Monday. 
     Display museum name, city.*/

select  m.museum_id, 
		m.name as museum_name, 
		m.city 
from	museum_hours mh
join	museum m on mh.museum_id = m.museum_id
where	day = 'sunday' and
		m.museum_id in(
						select m.museum_id
						from museum_hours mh
						join museum m on mh.museum_id = m.museum_id
						where day = 'monday'
					  );

/*8. Museums which are open every single day.*/

select  m.museum_id, 
		m.name as museum_name, 
		m.city,
		COUNT(distinct(day)) as Open_day
from	museum_hours mh
join	museum m on mh.museum_id = m.museum_id
group by m.museum_id, 
		m.name , 
		m.city
having COUNT(distinct(day)) = 7


/* 9. Top 5 most popular museum? (Popularity is defined based on most
      no of paintings in a museum)*/

with Popular_museum as	  
(
select	m.museum_id,
		m.name as museum_name,
		count(w.museum_id) as No_of_painting,
		DENSE_RANK () over(order by count(w.museum_id) desc) rnk
from work w
join museum m on w.museum_id = m.museum_id
group by m.museum_id,
		 m.name
)
select * from Popular_museum
where rnk <= 5;

/* 10. Top 5 most popular artist? 
(Popularity is defined based on most no of paintings done by an artist)*/

with popular_artist as
(
select  a.artist_id, 
		a.full_name,
		a.nationality,
		COUNT(w.artist_id) as No_of_paintings,
		DENSE_RANK() over (order by COUNT(w.artist_id) desc) as rnk
from work w
join artist a on w.artist_id = a.artist_id
group by a.artist_id, 
		 a.full_name,
		 a.nationality
)
select * from popular_artist
where rnk <= 5


/*11. Least 3 popular canvas sizes*/

with least_popular_canvas_sizes as
(
select	c.size_id, 
		c.label, 
		COUNT(c.size_id) No_of_label,
		DENSE_RANK() over(order by COUNT(c.size_id) asc) rnk
from work w
join product_size p on w.work_id = p.work_id
join canvas_size c on p.size_id = c.size_id
Group by c.size_id, 
		 c.label
)

select * from least_popular_canvas_sizes
where rnk <= 3


/*12.  Museum which open for the longest during a day. 
Dispayed museum name, state and hours open and which day?*/

with Logest_hour as
(
select  m.name as museum_name, 
		m.state,
		day,
		DATEDIFF(HOUR, [open],[close]) hours_open,
		DENSE_RANK() over (order by DATEDIFF(HOUR, [open],[close]) desc) as rnk
from museum_hours mh
join museum m on m.museum_id = mh.museum_id
)
select * from Logest_hour
where rnk = 1

/*13. Museum with no of most popular painting style?*/

with popular_painting_style as
(
select  m.name as museum_name,
		w.style,
		count(w.style) as Popular_style,
		DENSE_RANK() over(order by count(w.style) desc) as rnk
from work w
join museum m on w.museum_id = m.museum_id
group by m.name, 
		 w.style
)
select * from popular_painting_style
where rnk = 1


/*14. Artists whose paintings are displayed in multiple countries*/

with multiple_countries as
(
select distinct (a.artist_id),
       a.full_name,
	   m.country
	   from work w
join artist a on w.artist_id = a.artist_id
join museum m on m.museum_id = w.museum_id
)
select  artist_id,
		full_name,
	    count(country) as No_of_country,
	    DENSE_RANK() over(order by count(country) desc) rnk
from multiple_countries
group by artist_id,
		 full_name		 
having count(country) > 1

/*15.  Country and the city with most no of museums.*/

with most_museums_city as
(
select	city,
		count(city) No_of_city,
		DENSE_RANK() over(order by count(city) desc) as city_rnk
from museum
group by city
),
most_museums_country as
(
select	country,
		count(country) No_of_country,
		DENSE_RANK() over(order by count(country) desc) as country_rnk
from museum
group by country
)

select  country, 
		STRING_AGG(city,', ') city
from most_museums_country 
cross join most_museums_city 
where   city_rnk = 1 and
		country_rnk = 1
group by country;


/*16. Artist and the museum where the most expensive and least expensive painting is placed. 
Displayed the artist name, sale_price, painting name, museum name, museum city and canvas label*/


with least_and_most_expensive as
(
select  a.full_name,
		p.sale_price,
		w.name as painting_name,
		m.name as museum_name,
		m.city,
		c.label,
		DENSE_RANK() over(order by p.sale_price) least_expensive,
		DENSE_RANK() over(order by p.sale_price desc) Most_expensive
from work w
join product_size p on p.work_id = w.work_id
join museum m on w.museum_id = m.museum_id
join canvas_size c on c.size_id = p.size_id
join artist a on a.artist_id = w.artist_id
)

select  full_name,
		sale_price,
		painting_name,
		museum_name,
		city,
		label,
		case
		when least_expensive = 1 then 'least_expensive'
		when Most_expensive = 1 then 'Most_expensive'
		end as Expensive_type
from least_and_most_expensive
where  least_expensive = 1 or
	   Most_expensive = 1

/*17. Top countries with highest no of paintings?*/

with Top_countries as
(
select  m.country,
		COUNT(w.name) as No_of_paintings,
		DENSE_RANK() over (order by COUNT(w.name) desc) as rnk
from work w
join museum m on w.museum_id = m.museum_id
group by m.country 
)
select * from Top_countries
where rnk <=5


/*18. Displayed 3 most popular and 3 least popular painting styles?*/


with Popular_painting as
(
select  w.style, 
		count(w.style) as No_of_painting,
		DENSE_RANK() over(order by count(w.style) desc) Most_Popular_style,
		DENSE_RANK() over(order by count(w.style)) least_Popular_style
from work w
where w.style is not null
group by w.style
)

select  style,
		case
		when Most_Popular_style <=3 then 'Most_Popular_style'
		when Least_Popular_style <=3 then 'Least_Popular_style'
		end as Popular_style
from Popular_painting
where Most_Popular_style <=3 or
      least_Popular_style <=3


/*19. Artist with most no of Portraits paintings outside USA?. 
Displayed artist name, no of paintings and the artist nationality.*/


with Countries_other_than_USA as
(
select a.artist_id,
       a.full_name,
	   m.country,w.name
	   from work w
join artist a on w.artist_id = a.artist_id
join museum m on m.museum_id = w.museum_id
join subject s on s.work_id=w.work_id
where m.country <> 'USA' and
	  s.subject='Portraits'
),
No_of_painting as
(
select  artist_id,
		full_name,
	    count(name) as No_of_painting,
	    DENSE_RANK() over(order by count(name) desc) rnk
from Countries_other_than_USA
group by artist_id,
		 full_name		 
)
select * from No_of_painting
where rnk = 1


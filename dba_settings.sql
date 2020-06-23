select * from cinema.movies;

create user fan identified by fan;
grant connect to fan;
grant select on cinema.movies to fan;
create synonym fan.movies for cinema.movies;
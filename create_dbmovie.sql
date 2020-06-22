alter session set "_ORACLE_SCRIPT"=true;
drop user cinema cascade;

create user cinema identified by cinema;

grant connect,resource to cinema;
grant create view to cinema;
grant create role to cinema;
GRANT UNLIMITED TABLESPACE TO cinema;

connect cinema/cinema;

---------------------------------------------------------------------------
-- TABLES
---------------------------------------------------------------------------

create table stars(
	num_star number constraint pk_star primary key,
	name varchar2(100) NOT NULL,
	birthdate date NULL
);

create table movies(
	num_movie number constraint pk_movie primary key,
	num_director NULL constraint fk_movie references stars(num_star),
	title varchar2(250) NOT NULL,
	year number(4) NOT NULL constraint chk_movie_year check (year >= 1888),
	genre varchar2(50) DEFAULT 'Drama',
	duration number(3) NULL
);

create table play(
	num_actor constraint fk1_play references stars(num_star),
	num_movie constraint fk2_play references movies(num_movie),
	role varchar2(50),
	constraint pk_play primary key (num_actor,num_movie));


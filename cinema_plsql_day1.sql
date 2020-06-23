-- how to deal wit auto generated primary keys in oracle ?
-- answer : sequence + trigger
create sequence seq_stars;
create sequence seq_movies;

create or replace trigger trig_pk_stars
before insert on stars
for each row -- repeat the pl/sql bloc for each row inserted
begin
    -- special variable :new is asigned with th current row inserted  : NULL | a_name | a_birthdate
    select seq_stars.nextval INTO :new.num_star from dual;
end;
/

create or replace trigger trig_pk_movies
before insert on movies
for each row 
begin
    select seq_movies.nextval INTO :new.num_movie from dual;
end;
/


-- nextval is a new number for every transactions
select seq_stars.nextval from dual;
-- currval is the last number generated in this transaction
select seq_stars.currval from dual;


-- insert into stars (num_star,name) values(1,'Stéphanie');
-- insert into stars (num_star,name) values(2,'Guillaume Pierret');
insert into stars (name) values('Stéphanie');
insert into stars (name) values('Guillaume Pierret');
insert into movies (title, year, num_director) values ('Balle Perdue',2020, 22); 
insert into movies (title, year) values ('Pulp Fiction',1994); 
select * from stars;
select * from movies;

commit;
rollback;

select count(*) as nb from stars;  -- 1 result/row
select * from stars where num_star = 50; -- 0/1 result/row
select * from stars where name like '%a%'; -- 0 to n results/rows
select title, year from movies where num_movie = 1;
select * from movies where num_movie = 1;


set SERVEROUTPUT ON;

-- Notion of PL/SQL block  for a trigger, function, procedure or standalone
declare -- keyword mandatory in standalone, forbidden for function/procedure, 
        -- only if local variables with triggers
    type t_title_year is record (
        title movies.title%type,
        year movies.year%type);
    v_nb_stars number;
    v_name stars.name%type; --varchar2(100);
    v_title movies.title%type;
    v_year movies.year%type;
    v_movie movies%rowtype;
    v_title_year t_title_year;
begin
    -- instructions
    dbms_output.put_line('Add stars');  -- procedure put_line du package dbms_output
    -- ordre SQL DML (data manipulation language : insert, update, delete, select)
    insert into stars (name) values('Alban Lenoir');
    commit;
    select count(*) into v_nb_stars from stars;  -- statement with 1 row result (100%)
    -- select name into v_name from stars where num_star = 22;  -- statement with  0/1 row result 
        -- 99% ok if primary key well handled but no data found error is possible
    --select name into v_name from stars where birthdate is null; -- req à n résultats
        -- 99% chance of having too many rows error
    
    -- select title, year into v_title, v_year from movies where num_movie = 1;
    -- dbms_output.put_line('Title : ' || v_title || ', year = ' || v_year);
    
    -- select * into v_movie from movies where num_movie = 1;
    -- dbms_output.put_line('Title : ' || v_movie.title || ', year = ' || v_movie.year);
    select title, year into v_title_year from movies where num_movie = 1;
    dbms_output.put_line('Title : ' || v_title_year.title || ', year = ' || v_title_year.year);
    
    
    dbms_output.put_line('Added : ' || v_name);
    dbms_output.put_line('End of updates. Number of stars = ' || v_nb_stars);
end;
/

rollback;

select title, case when year > 2000 then 'Recent' else 'Classic' end
from movies;

-------------------------------------------------------------
-- conditonal structures  : if/case
-------------------------------------------------------------
declare
    v_nb_stars number; -- or pls_integer
begin
    select count(*) into v_nb_stars from stars where birthdate is null;
    if v_nb_stars = 0 then -- test with comparison operator 
        -- null; -- TODO : à faire
        DBMS_OUTPUT.PUT_LINE('Nothing to do');
    elsif v_nb_stars < 10 then 
        begin -- sub-block is possible here (variable declarations, exception handling)
            DBMS_OUTPUT.PUT_LINE('Less than 10 stars to complete');
        end;
    else
        DBMS_OUTPUT.PUT_LINE('A lot of stars to complete (1)');
        DBMS_OUTPUT.PUT_LINE('A lot of stars to complete (2)');
    end if;
end;
/
 
-- same thing with a case
declare
    v_nb_stars number; -- or pls_integer
begin
    select count(*) into v_nb_stars from stars where birthdate is null;
    case
        when v_nb_stars = 0 then 
            DBMS_OUTPUT.PUT_LINE('Nothing to do');
        when v_nb_stars < 10 then 
            DBMS_OUTPUT.PUT_LINE('Less than 10 stars to complete');        
        else
            DBMS_OUTPUT.PUT_LINE('A lot of stars to complete (1)');
            DBMS_OUTPUT.PUT_LINE('A lot of stars to complete (2)');
        end CASE;
end;
/

-- case to inspect values of one variable (or expression)
declare
    v_year number; 
begin
    select min(year) into v_year from movies where year between 2020 and 2029;
    if v_year is not null then
        case v_year
            when 2020 then 
                DBMS_OUTPUT.PUT_LINE('Movie of the first year of a decade');
            when 2021 then 
                DBMS_OUTPUT.PUT_LINE('Movie of the second year of a decade');
            else
                DBMS_OUTPUT.PUT_LINE('Other year in the decade');
        end case;
    end if;
end;
/

select min(year) from movies where year between 2020 and 2029;
select min(year) from movies where year between 2000 and 2009;
select year from movies where year between 2000 and 2009;

-- trigger (event) or function (compute a value as a result) or procedure (treatment)

create or replace function nb_movie_decade(p_decade pls_integer) RETURN pls_integer is
    v_nb_movies pls_integer;
begin
    select count(*) into v_nb_movies from movies where year between p_decade*10 and p_decade*10+9;
    return v_nb_movies;
end;
/
select nb_movie_decade(199) from dual;

-- fonction with a parameter date and returning an age computed relatively to current year
select sysdate from dual;
select extract(year from sysdate) from dual;

create or replace function age(p_date date) return pls_integer is
    v_age pls_integer;
begin
    select extract(year from sysdate) - extract(year from p_date) into v_age from dual;
    return v_age;
end;
/

insert into stars (name, birthdate) 
	values('Steve McQueen','24/03/1930');
select age(to_date('01/07/2000','DD/MM/YYYY')) from dual;  --  --> 20
select name, birthdate, age(birthdate) from stars;

alter session set nls_date_format = 'DD/MM/YYYY';
alter session set nls_date_format = 'YYYYMMDD';
select sysdate from dual;



-- procedure with a parameter p_decade (IN mode)
-- limit : all DML except dynamic SQL
create or replace procedure report_decade(p_decade pls_integer) is
    v_nb_movies pls_integer;
begin
    select count(*) into v_nb_movies from movies where year between p_decade*10 and p_decade*10+9;
    dbms_output.put_line(v_nb_movies);
end;
/

declare
    v_decade pls_integer := 200;
begin
    report_decade(v_decade);
end;
/

call report_decade(200);
execute report_decade(200);


show errors;

select title, year, year/10 from movies;


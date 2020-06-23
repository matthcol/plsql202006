set SERVEROUTPUT ON;

-- v0 : version without exception, no error handling
create or replace procedure add_movie(
    p_title movies.title%type, -- mode IN default (IN, OUT, IN OUT)
    p_year movies.year%type,
    p_duration movies.duration%type default NULL,
    p_genre movies.genre%type default 'Drama',
    p_name stars.name%type,
    p_num_movie OUT movies.num_movie%type)
is
    v_nb_director pls_integer;
    v_num_director stars.num_star%type;
begin
    -- director with name p_name exists ?
    select count(*) into v_nb_director from stars where name like p_name;
    if v_nb_director > 0 then -- director exists in the database
        dbms_output.put_line(p_name || ' exists');
        -- retrieve his id
        select num_star into v_num_director from stars where name like p_name;
    else
        dbms_output.put_line(p_name || ' doesn''t exist');
        -- insert the missing director in the table stars and retrieve his id
        insert into stars (name) values (p_name);
        v_num_director := SEQ_STARS.currval;
    end if;
    -- we known the director by his id, let's insert the movie with the right foreign key
    insert into movies (title,year,duration,genre,num_director)
        values (p_title, p_year, p_duration, p_genre, v_num_director);
    p_num_movie := SEQ_MOVIES.currval;
end;
/

-- v1 : version with exception internaly, no error propagation outside
-- returns a movie id NULL if there is a problem
create or replace procedure add_movie(
    p_title movies.title%type, -- mode IN default (IN, OUT, IN OUT)
    p_year movies.year%type,
    p_duration movies.duration%type default NULL,
    p_genre movies.genre%type default 'Drama',
    p_num_director stars.num_star%type default NULL,
    p_name stars.name%type default NULL,
    p_num_movie OUT movies.num_movie%type)
is
    ex_title_year_not_provided exception; -- user exception with manual raise
    ex_num_director_unknown exception; -- user exception associated with known oracle error code
    PRAGMA EXCEPTION_INIT (ex_num_director_unknown, -2291);
    
    v_num_director stars.num_star%type := p_num_director;
begin
    if p_title is null or p_year is null then
        raise ex_title_year_not_provided;
    end if;
    if p_num_director is NULL and p_name is not null then
        begin
            -- le realisateur p_name existe-t-il ? 3 cas : 
            -- 0 (no_data_found),1 (ok) ou plusieurs stars (too_many_rows)
            select num_star into v_num_director from stars where name like p_name;
            dbms_output.put_line(p_name || ' exists');
        exception
            when no_data_found then 
                dbms_output.put_line(p_name || ' doesn''t exist');
                insert into stars (name) values (p_name);
                v_num_director := SEQ_STARS.currval;
        end;
    -- elif p_num_director is null and p_name is null 
    --    => nothing todo : we will insert the movie with a foreign key NULL (value of p_num_director)
    -- elif p_num_director is not null
    --    => nothing todo ; we will try to insert the movie with the right id
    -- TODO : cleaner if we forbid both p_num_director and p_name not null
    end if;
    -- we have now an id for the director or NULL if id and p_name are not provided
    -- try the insert with the director id
    -- if wrong number (only if provided as a parameter), we will have ex_num_director_unknown raised
    -- as we have tied this exception with oracle error code -2291
    insert into movies (title,year,duration,genre,num_director)
        values (p_title, p_year, p_duration, p_genre, v_num_director);
    -- if the insert if correct, we retrieve the last id generated in this transaction
    -- to return it with the OUT parameter
    p_num_movie := SEQ_MOVIES.currval;
     dbms_output.put_line('Movie added : ' || p_title || ' with id ' || p_num_movie);
exception
    when too_many_rows then -- the director has homonymous
        dbms_output.put_line('Movie not added : homonymous directors ' || p_name 
        || ' (oracle error '|| SQLCODE || ')');
    when ex_num_director_unknown then
        dbms_output.put_line('Movie not added : director id unknown: ' || p_num_director 
            || ' (oracle error '|| SQLCODE || ')');
    when ex_title_year_not_provided then
        dbms_output.put_line('Movie not added : title or year not provided <' 
                || p_title || ', ' || p_year || '>'
                || ' (oracle error '|| SQLCODE || ')');
end;
/

-- v2 : version with exception internally
-- raise oracle error with application specific error codes
create or replace procedure add_movie(
    p_title movies.title%type, -- mode IN default (IN, OUT, IN OUT)
    p_year movies.year%type,
    p_duration movies.duration%type default NULL,
    p_genre movies.genre%type default 'Drama',
    p_num_director stars.num_star%type default NULL,
    p_name stars.name%type default NULL,
    p_num_movie OUT movies.num_movie%type)
is
    ex_title_year_not_provided exception; -- user exception with manual raise
    ex_num_director_unknown exception; -- user exception associated with known oracle error code
    PRAGMA EXCEPTION_INIT (ex_num_director_unknown, -2291);
    
    v_num_director stars.num_star%type := p_num_director;
begin
    if p_title is null or p_year is null then
        raise ex_title_year_not_provided;
    end if;
    if p_num_director is NULL and p_name is not null then
        begin
            -- le realisateur p_name existe-t-il ? 3 cas : 
            -- 0 (no_data_found),1 (ok) ou plusieurs stars (too_many_rows)
            select num_star into v_num_director from stars where name like p_name;
            dbms_output.put_line(p_name || ' exists');
        exception
            when no_data_found then 
                dbms_output.put_line(p_name || ' doesn''t exist');
                insert into stars (name) values (p_name);
                v_num_director := SEQ_STARS.currval;
        end;
    -- elif p_num_director is null and p_name is null 
    --    => nothing todo : we will insert the movie with a foreign key NULL (value of p_num_director)
    -- elif p_num_director is not null
    --    => nothing todo ; we will try to insert the movie with the right id
    -- TODO : cleaner if we forbid both p_num_director and p_name not null
    end if;
    -- we have now an id for the director or NULL if id and p_name are not provided
    -- try the insert with the director id
    -- if wrong number (only if provided as a parameter), we will have ex_num_director_unknown raised
    -- as we have tied this exception with oracle error code -2291
    insert into movies (title,year,duration,genre,num_director)
        values (p_title, p_year, p_duration, p_genre, v_num_director);
    -- if the insert if correct, we retrieve the last id generated in this transaction
    -- to return it with the OUT parameter
    p_num_movie := SEQ_MOVIES.currval;
     dbms_output.put_line('Movie added : ' || p_title || ' with id ' || p_num_movie);
exception
    -- user error code must within the range : -20999 à -20000
    when too_many_rows then -- the director has homonymous
        RAISE_APPLICATION_ERROR(-20000, 'Movie not added : il existe des homonymes ' || p_name );
    when ex_num_director_unknown then
        RAISE_APPLICATION_ERROR(-20001,'Movie not added : director id unknown ' || p_num_director );
    when ex_title_year_not_provided then
        RAISE_APPLICATION_ERROR(-20002,'Movie not added : title or year not provided <' 
                || p_title || ', ' || p_year || '>');
end;
/


-- tests of add_movie procedure
declare
    v_num_movie movies.num_movie%type;
begin
    -- 1. without a director :
    add_movie('Django Unchained',2012,165, p_num_movie=>v_num_movie);
    -- 2. with a director already in the database (no homonyms) :
    add_movie('Kill Bill: Vol. 1',2003,111, p_name=>'Quentin Tarantino', p_num_movie=>v_num_movie);
    dbms_output.put_line('(main) Movie added with id: ' || v_num_movie); 
    -- 3. with a new director :
    add_movie('Unforgiven',1992, p_name=>'Clint Eastwood', p_num_movie=>v_num_movie);
    -- 4. with the director just added before :
    add_movie('Gran Torino',2008, p_name=>'Clint Eastwood', p_num_movie=>v_num_movie);
    -- 5. Error : with a director already there but with homonyms :
    add_movie('Shame',2011, p_name=>'Steve McQueen', p_num_movie=>v_num_movie);
    -- 6. no ambiguity with the birthdate :
    -- add_movie('Shame',2011, p_name=>'Steve McQueen',p_birthdate=>'09/10/1969', p_num_movie=>v_num_movie);
    -- 7. Add movie with director known by id :
    add_movie('Hunger',2008, p_num_director=> 2, p_num_movie=>v_num_movie);
    -- 8. Error : with a wrong foreign key :
    add_movie('12 Years A Slave',2013, p_num_director=>100000, p_num_movie=>v_num_movie);
    -- 9.10.11. Errors : no title or no year for the movie
    add_movie(NULL,2008, p_num_movie=>v_num_movie);
    add_movie('The Getaway',NULL, p_num_movie=>v_num_movie);
    add_movie(NULL,NULL, p_num_movie=>v_num_movie);
end;
/

-- check the data :
select * from movies left join stars on num_director = num_star;
-- or
select s.*, listagg(m.title, ', ') within group (order by year) as filmographie
from stars s left join movies m on num_director = num_star group by num_star, name, birthdate;

-- rollback the previous scenario
rollback;
commit;

-- some example of oracle error codes
-- 1. foreign key constraint violated : error  code ORA-02291 (no pl/sql predefined exception)
insert into movies (title,year,num_director) values ('Barkskins',2020, 100000 ); 
-- 2. unique constraint violated : error code ORA-00001 (predefined exception DUP_VAL_ON_INDEX)
update movies set num_movie = 31 where num_movie = 32; -- id 31 is already taken
select * from movies;
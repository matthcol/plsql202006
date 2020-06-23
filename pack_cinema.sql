-- 1. visible part of a package : only declarations of function/procedure/exception/types
create or replace package pack_cinema is
    ex_num_director_unknown exception;
    ex_title_year_not_provided exception;
    PRAGMA EXCEPTION_INIT (ex_num_director_unknown, -2291);
    type t_cursor_movies is ref cursor return movies%rowtype;
    
    function age(p_date date) return pls_integer;
    procedure add_movie(
        p_title movies.title%type, -- mode IN default (IN, OUT, IN OUT)
        p_year movies.year%type,
        p_duration movies.duration%type default NULL,
        p_genre movies.genre%type default 'Drama',
        p_num_director stars.num_star%type default NULL,
        p_name stars.name%type default NULL,
        p_num_movie OUT movies.num_movie%type);
    procedure report_movies(cur_movies t_cursor_movies);

end pack_cinema;
/

-- 2. invisible part of the package (implementaion) : BODY
create or replace package body pack_cinema is
    
    function age(p_date date) return pls_integer is
        v_age pls_integer;
    begin
        select extract(year from sysdate) - extract(year from p_date) into v_age from dual;
        return v_age;
    end;
    
    procedure add_movie(
        p_title movies.title%type, -- mode IN default (IN, OUT, IN OUT)
        p_year movies.year%type,
        p_duration movies.duration%type default NULL,
        p_genre movies.genre%type default 'Drama',
        p_num_director stars.num_star%type default NULL,
        p_name stars.name%type default NULL,
        p_num_movie OUT movies.num_movie%type)
    is
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

    procedure report_movies(cur_movies t_cursor_movies) is
        v_movie movies%rowtype;
    begin
        -- TODO : tester curseur is open
        loop
            fetch cur_movies into v_movie;
            exit when cur_movies%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE(v_movie.title || ' (' || v_movie.year || ')');
        end loop;
        close cur_movies;
    end;

end pack_cinema;
/

-- test the package
-- test function age
select pack_cinema.age(sysdate) from dual;

-- test procedure add_movie
declare
    v_num_movie movies.num_movie%type;
begin
    pack_cinema.add_movie('Kill Bill: Vol. 2',2005, p_name=>'Quentin Tarantino', p_num_movie=>v_num_movie);
end;
/

-- test report_movie with ref cursor and different select statements
declare
    cur_movies pack_cinema.t_cursor_movies;
begin
    open cur_movies for select * from movies where year < 1985;
    pack_cinema.report_movies(cur_movies);
    open cur_movies for select * from movies where title like 'Kill%';
    pack_cinema.report_movies(cur_movies);
end;
/

-- a small example of dynamic SQL
declare
    v_table VARCHAR2(20);
    request varchar2(150);
begin
    v_table := 'movies';
    request := 'delete from ' || v_table;
    execute immediate request;
end;
/


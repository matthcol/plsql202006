-- Loops in PL/SQL

-- modern for loop : 1 2 3 ... 9 10
declare
    i pls_integer;
begin
    i := 45; -- i declared explicitly
    for i in 1..10 loop -- iteration variable implicitly declared (different from previous i)
        DBMS_OUTPUT.PUT_LINE('i = '|| i);  -- i implicit from the for loop
    end loop;
    DBMS_OUTPUT.PUT_LINE('After loop : i = '|| i); -- back to explicit variable i
end;
/

-- loop with step : 3 6 9 12 ... 30
declare
    step pls_integer := 3;
begin
    for i in 1..10 loop 
        DBMS_OUTPUT.PUT_LINE('i = '|| i*step); 
    end loop;
end;
/

-- reverse loop : 10 9 8 7 6 5 4 3 2 1
declare
begin
    for i in reverse 1..10 loop 
        DBMS_OUTPUT.PUT_LINE('i = '|| i);
    end loop;
end;
/

-- old school loop
declare
    i pls_integer :=1;
begin
    loop 
        DBMS_OUTPUT.PUT_LINE('boucle : ' || i);
        i := i+1;
        exit when i = 10;
    end loop;
    DBMS_OUTPUT.PUT_LINE('Après boucle : ' || i);
end;
/


-- example : loop to insert severals rows (film franchise)
declare
begin
    for i in reverse 1..5 loop 
        insert into movies (title,year)  values ('Rocky ' || i, 1974 + 2*i);
    end loop;
end;
/

-- example : interrupt iteration of for loop when some predicate is true
declare
    v_nb_movie pls_integer;
begin
    -- looking for the missing Rocky movie
    for i in 1..5 loop 
        select count(*) into v_nb_movie from movies where title like ('Rocky '|| i);
        DBMS_OUTPUT.PUT_LINE('Trouvé : ' || v_nb_movie);
        exit when v_nb_movie = 0;
    end loop;
end;
/

-- example : intermediate commit in a for loop
declare
    step_commit pls_integer := 100;
begin
    for i in 1..100000 loop 
        insert into movies (title,year)  values ('Naruto '|| i, 1990);
        if i mod step_commit = 0 then
            commit;
        end if;
    end loop;
end;
/

-- Using loops to deal n result rows from a select statement

-- modern and simplier form
declare
    cursor cur_movies is 
        select title, year, extract(year from sysdate) - year as age from movies;
begin
    -- v_movie iteration variable implictly declared with a record type
    --      adapted with projected colums of the statement
    -- before the first iteration, the request automatically est executed (OPEN)
    for v_movie in cur_movies loop
        -- each iteration, the cursor move to next row 
        -- and assign the current row to the iteration variable (FETCH)
        DBMS_OUTPUT.PUT_LINE(v_movie.title || ' (' || v_movie.year 
                || '), il y a ' || v_movie.age || ' ans');
    end loop;
    -- when exiting the loop, the cursor is closed (CLOSE)
end;
/

-- same thing without cursor declaration
declare
begin
    for v_movie in (
            select title, year, extract(year from sysdate) - year as age from movies) 
    loop
        DBMS_OUTPUT.PUT_LINE(v_movie.title || ' (' || v_movie.year 
                || '), il y a ' || v_movie.age || ' ans');
    end loop;
end;
/

-- classic form of curseur treatment : open,fetch,close explicit
declare
    cursor cur_movies is 
        select * from movies;
    v_movie movies%rowtype; -- explicit declaration of iteration variable (with the right record declaration)
begin
    IF cur_movies%ISOPEN THEN
        DBMS_OUTPUT.PUT_LINE('Curseur ouvert');
    else
        DBMS_OUTPUT.PUT_LINE('Curseur fermé');
    end if;
    open cur_movies; -- execute the statement
    IF cur_movies%ISOPEN THEN
        DBMS_OUTPUT.PUT_LINE('Curseur ouvert');
    else
        DBMS_OUTPUT.PUT_LINE('Curseur fermé');
    end if;
    loop
        -- move to next row in the result and assign it to a variable
        fetch cur_movies into v_movie;
        exit when cur_movies%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(v_movie.title || ' (' || v_movie.year 
                || ')');
    end loop;
    DBMS_OUTPUT.PUT_LINE('Lus : ' || cur_movies%ROWCOUNT || ' movies');
    close cur_movies;  -- bien penser à fermer le curseur
       IF cur_movies%ISOPEN THEN
        DBMS_OUTPUT.PUT_LINE('Curseur ouvert');
    else
        DBMS_OUTPUT.PUT_LINE('Curseur fermé');
    end if;
end;
/

-- parameterized cursor
create or replace procedure read_movies is
    cursor cur_movies(p_year movies.year%type) is 
        select title, year from movies where year = p_year;
    v_year1 movies.year%type;
    v_year2 movies.year%type;
begin
    -- compute years before select/cursor statement
    select min(year), max(year) into v_year1, v_year2 from movies;
    -- then open the cursor with the computed data
    for v_movie in cur_movies(v_year1) loop
        DBMS_OUTPUT.PUT_LINE(v_movie.title || ' (' || v_movie.year || ')');
    end loop;
    for v_movie in cur_movies(v_year2) loop
        DBMS_OUTPUT.PUT_LINE(v_movie.title || ' (' || v_movie.year || ')');
    end loop;
end;
/

call read_movies();


-- dynamic predicate with REF CURSOR
create or replace procedure report_movies_predicate_dynamic is
    type t_cursor_movies is ref cursor return movies%rowtype;
    cur_movies t_cursor_movies;
    v_movie movies%rowtype;
begin
    -- first deal with some request returning movies
    open cur_movies for select * from movies where year < 1985;
    -- secondly, deal with this cursor to deal with the results of the previous statement
    -- these two parts can be splitted (cf package version) 
    loop
        fetch cur_movies into v_movie;
        exit when cur_movies%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(v_movie.title || ' (' || v_movie.year || ')');
    end loop;
    close cur_movies;
end;
/

call report_movies_predicate_dynamic();

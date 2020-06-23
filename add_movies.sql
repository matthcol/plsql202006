create or replace procedure add_movie(
    p_title movies.title%type,
    p_year movies.year%type,
    p_duration movies.duration%type default NULL,
    p_genre movies.genre%type default 'Drama',
    p_name stars.name%type,
    p_num_movie OUT movies.num_movie%type)
is
begin
    null;
end;
/



declare
    v_num_movie movies.num_movie%type;
begin
    -- without a director :
    add_movie('Django Unchained',2012,165, p_num_movie=>v_num_movie);
    -- with a director already in the database (no homonyms) :
    add_movie('Kill Bill: Vol. 1',2003,111, p_name=>'Quentin Tarantino', p_num_movie=>v_num_movie);
    -- with a new director :
    add_movie('Unforgiven',1992, p_name=>'Clint Eastwood', p_num_movie=>v_num_movie);
    -- with the director just added before :
    add_movie('Gran Torino',2008, p_name=>'Clint Eastwood', p_num_movie=>v_num_movie);
    -- Error : with a director already there but with homonyms :
    add_movie('Shame',2011, p_name=>'Steve McQueen', p_num_movie=>v_num_movie);
    -- no ambiguity with the birthdate :
    add_movie('Shame',2011, p_name=>'Steve McQueen',p_birthdate=>'09/10/1969', p_num_movie=>v_num_movie);
    -- Add movie with director known by id :
    add_movie('Hunger',2008, p_num_director=> 5, p_num_movie=>v_num_movie);
    -- Error : with a wrong primary key :
    add_movie('12 Years A Slave',2013, p_num_director=>100000, p_num_movie=>v_num_movie);
    -- Errors : no title or no year for the movie
    add_movie(NULL,2008, p_num_movie=>v_num_movie);
    add_movie('The Getaway',NULL, p_num_movie=>v_num_movie);
    add_movie(NULL,NULL, p_num_movie=>v_num_movie);
end;
/

-- check the data :
select * from movies left join stars on num_director = num_star;

select s.*, listagg(m.title, ', ') within group (order by year) as filmographie
from stars s left join movies m on num_director = num_star group by num_star, name, birthdate;

-- rollback the previous scenario
rollback;
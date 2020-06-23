create sequence seq_stars;
create sequence seq_movies;

create or replace trigger trig_pk_stars
before insert on stars -- before checking integrity constraints
for each row -- to deal with each row inserted
begin
    -- :new désigne la ligne en cours d'insertion  : 
	-- num_star | name   | birthdate
	-- NULL     | a_name | a_birthdate
    select seq_stars.nextval INTO :new.num_star from dual;
end;
/

create or replace trigger trig_pk_movies
before insert on movies
for each row 
begin
    -- autre écriture pour affecter le numero de sequence
    :new.num_movie := seq_movies.nextval;
end;
/

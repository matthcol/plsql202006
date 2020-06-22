create sequence seq_stars;


create or replace trigger trig_pk_stars
before insert on stars
for each row -- pour pouvir accéder à chaque ligne modifiée
begin
    -- :new désigne la ligne en cours d'insertion  : NULL | name | birthdate
    select seq_stars.nextval INTO :new.num_star from dual;
end;
/

select seq_stars.nextval from dual;
select seq_stars.currval from dual;


-- insert into stars (num_star,name) values(1,'Stéphanie');
-- insert into stars (num_star,name) values(2,'Guillaume Pierret');
insert into stars (name) values('Stéphanie');
insert into stars (name) values('Guillaume Pierret');

select * from stars;

commit;
rollback;
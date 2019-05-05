drop table if exists Sgif.d_evento cascade;
drop table if exists Sgif.d_meio cascade;
drop table if exists Sgif.d_tempo cascade;
drop table if exists Sgif.tf_eventos_meios cascade;

create table Sgif.d_evento (
    idEvento serial, -- num evento
    numTelefone numeric(9, 0) not null,
    instanteChamada timestamp not null,
    constraint pk_d_evento primary key(idEvento)
);

create table Sgif.d_meio (
    idMeio serial,
    numMeio int not null,
    nomeMeio varchar(40) not null,
    nomeEntidade varchar(40) not null, 
    tipo varchar(40), 
    constraint pk_d_meio primary key(idMeio)
);

create table Sgif.d_tempo (
    idData serial,
    dia numeric(2, 0) not null, 
    mes numeric(2, 0) not null,
    ano numeric(4, 0) not null,
    constraint pk_d_tempo primary key(idData)
);

create table Sgif.tf_eventos_meios (
    idEvento int, 
    idMeio int, 
    idData int,
    constraint pk_tf_eventos_meios primary key(idEvento, idMeio, idData),
    constraint fk_evento foreign key(idEvento) references Sgif.d_evento on delete cascade,
    constraint fk_meio foreign key(idMeio) references Sgif.d_meio on delete cascade,
    constraint fk_tempo foreign key(idData) references Sgif.d_tempo on delete cascade
);

INSERT INTO Sgif.d_evento (numTelefone, instanteChamada) -- serial numbers inserted automatically.
SELECT numTelefone, instanteChamada
FROM Sgif.EventoEmergencia;

INSERT INTO Sgif.d_meio (numMeio, nomeMeio, nomeEntidade, tipo)
SELECT numMeio, nomeMeio, nomeEntidade, 'combate'
FROM Sgif.Meio NATURAL JOIN Sgif.MeioCombate;

INSERT INTO Sgif.d_meio (numMeio, nomeMeio, nomeEntidade, tipo)
SELECT numMeio, nomeMeio, nomeEntidade, 'apoio'
FROM Sgif.Meio NATURAL JOIN Sgif.MeioApoio;

INSERT INTO Sgif.d_meio (numMeio, nomeMeio, nomeEntidade, tipo)
SELECT numMeio, nomeMeio, nomeEntidade, 'socorro'
FROM Sgif.Meio NATURAL JOIN Sgif.MeioSocorro;

INSERT INTO Sgif.d_meio (numMeio, nomeMeio, nomeEntidade, tipo)
SELECT M.numMeio, M.nomeMeio, M.nomeEntidade, 'sem-tipo'
FROM Sgif.Meio M
WHERE NOT EXISTS (
    SELECT *
    FROM Sgif.MeioCombate C
    WHERE M.numMeio = C.numMeio
) AND NOT EXISTS (
    SELECT *
    FROM Sgif.MeioApoio A
    WHERE M.numMeio = A.numMeio
) AND NOT EXISTS (
    SELECT *
    FROM Sgif.MeioApoio S
    WHERE M.numMeio = S.numMeio
);

INSERT INTO Sgif.d_tempo (dia, mes, ano)
SELECT DISTINCT
    EXTRACT(DAY FROM instanteChamada),
    EXTRACT(MONTH FROM instanteChamada),
    EXTRACT(YEAR FROM instanteChamada)
FROM Sgif.EventoEmergencia;

INSERT INTO Sgif.tf_eventos_meios (idEvento, idMeio, idData)
SELECT idEvento, idMeio, idData
FROM Sgif.Acciona NATURAL JOIN Sgif.EventoEmergencia NATURAL JOIN Sgif.d_evento NATURAL JOIN Sgif.d_meio NATURAL JOIN Sgif.d_tempo;

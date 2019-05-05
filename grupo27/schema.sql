----------------------------------------
-- Create Schema
----------------------------------------
create schema if not exists Sgif;


----------------------------------------
-- Drops
----------------------------------------
drop table if exists Sgif.Camara cascade;
drop table if exists Sgif.Video cascade;
drop table if exists Sgif.SegmentoVideo cascade;
drop table if exists Sgif.Local cascade;
drop table if exists Sgif.Vigia cascade;
drop table if exists Sgif.EventoEmergencia cascade;
drop table if exists Sgif.ProcessoSocorro cascade;
drop table if exists Sgif.EntidadeMeio cascade;
drop table if exists Sgif.Meio cascade;
drop table if exists Sgif.MeioCombate cascade;
drop table if exists Sgif.MeioApoio cascade;
drop table if exists Sgif.MeioSocorro cascade;
drop table if exists Sgif.Transporta cascade;
drop table if exists Sgif.Alocado cascade;
drop table if exists Sgif.Acciona cascade;
drop table if exists Sgif.Coordenador cascade;
drop table if exists Sgif.Audita cascade;
drop table if exists Sgif.Solicita cascade;

drop domain if exists Sgif.NUM_CAMARA;
drop domain if exists Sgif.DATA_HORA_INICIO;
drop domain if exists Sgif.NUM_SEGMENTO;
drop domain if exists Sgif.MORADA_LOCAL;
drop domain if exists Sgif.NUM_TELEFONE;
drop domain if exists Sgif.INSTANTE_CHAMADA;
drop domain if exists Sgif.NUM_PROCESSO_SOCORRO;
drop domain if exists Sgif.NOME_ENTIDADE;
drop domain if exists Sgif.NUM_MEIO;
drop domain if exists Sgif.ID_COORDENADOR;
drop domain if exists Sgif.DATA_HORA_INICIO_VIDEO;


----------------------------------------
-- Domains
----------------------------------------

create domain Sgif.NUM_CAMARA as int;
create domain Sgif.DATA_HORA_INICIO as timestamp;
create domain Sgif.NUM_SEGMENTO as int;
create domain Sgif.MORADA_LOCAL as varchar(50);
create domain Sgif.NUM_TELEFONE as numeric(9, 0);
create domain Sgif.INSTANTE_CHAMADA as timestamp;
create domain Sgif.NUM_PROCESSO_SOCORRO as int;
create domain Sgif.NOME_ENTIDADE as varchar(20);
create domain Sgif.NUM_MEIO int;
create domain Sgif.ID_COORDENADOR as int;
create domain Sgif.DATA_HORA_INICIO_VIDEO as timestamp;

----------------------------------------
-- Triggers
----------------------------------------

-- Um Coordenador so pode solicitar vídeos de câmaras colocadas num local cujo accionamento de meios esteja a ser 
-- (ou tenha sido) auditado por ele proprio.
CREATE OR REPLACE FUNCTION Sgif.insert_solicita() RETURNS TRIGGER 
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT *
    FROM Sgif.Audita NATURAL JOIN Sgif.EventoEmergencia NATURAL JOIN Sgif.Vigia 
    WHERE idCoordenador = new.idCoordenador AND dataHoraInicio = new.dataHoraInicioVideo AND numCamara = new.numCamara
  )
  THEN 
    RAISE EXCEPTION 'Nao e possivel solicitar o video.';
  
  END IF;
  RETURN new;

END
$$ LANGUAGE plpgsql;

-- Um Meio de Apoio so pode ser alocado a processos de socorro para os quais tenha sido accionado
CREATE OR REPLACE FUNCTION Sgif.insert_alocado() RETURNS TRIGGER
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT *
    FROM Sgif.MeioApoio NATURAL JOIN Sgif.Acciona
    WHERE numProcessoSocorro = new.numProcessoSocorro
  )
  THEN
    RAISE EXCEPTION 'Nao e possivel alocar o meio de apoio.';
  END IF;
  RETURN new;
END
$$ LANGUAGE plpgsql;

----------------------------------------
-- Table Creation
----------------------------------------

create table Sgif.Camara (
  numCamara Sgif.NUM_CAMARA,
  constraint pk_camara primary key(numCamara)
);

create table Sgif.Video (
  dataHoraInicio Sgif.DATA_HORA_INICIO,
  dataHoraFim timestamp,
  numCamara Sgif.NUM_CAMARA,
  constraint pk_video primary key(dataHoraInicio, numCamara),
  constraint fk_num_camara foreign key(numCamara) references Sgif.Camara(numCamara)
);

create table Sgif.SegmentoVideo (
  numSegmento Sgif.NUM_SEGMENTO,
	duracao time,
	dataHoraInicio Sgif.DATA_HORA_INICIO,
	numCamara Sgif.NUM_CAMARA,
	constraint pk_segmento_video primary key(numSegmento, dataHoraInicio, numCamara),
	constraint fk_data_hora_inicio_num_camara foreign key(dataHoraInicio, numCamara) references Sgif.Video
);

create table Sgif.Local (
  moradaLocal Sgif.MORADA_LOCAL not null,
  constraint pk_local primary Key(moradaLocal)
);

create table Sgif.Vigia (
  moradaLocal Sgif.MORADA_LOCAL not null,
  numCamara Sgif.NUM_CAMARA not null,
  constraint pk_vigia primary key(moradaLocal, numCamara),
  constraint fk_morada_local foreign key(moradaLocal) references Sgif.Local(moradaLocal),
  constraint fk_num_camara foreign key(numCamara) references Sgif.Camara(numCamara)
);

create table Sgif.ProcessoSocorro (
  numProcessoSocorro Sgif.NUM_PROCESSO_SOCORRO,
  constraint pk_processo_socorro primary key(numProcessoSocorro)
);

create table Sgif.EventoEmergencia (
  numTelefone Sgif.NUM_TELEFONE not null, --unique
  instanteChamada Sgif.INSTANTE_CHAMADA not null,
  nomePessoa varchar(50) not null, --unique
  moradaLocal Sgif.MORADA_LOCAL not null,
  numProcessoSocorro Sgif.NUM_PROCESSO_SOCORRO, -- RI: numProcessoSocorro pode ser null
  constraint pk_evento_emergencia primary key(numTelefone, instanteChamada),
  constraint fk_morada_local foreign key(moradaLocal) references Sgif.Local(moradaLocal),
  constraint fk_num_processo_socorro foreign key(numProcessoSocorro) references Sgif.ProcessoSocorro(numProcessoSocorro),
  unique(numTelefone, nomePessoa)
);

create table Sgif.EntidadeMeio (
  nomeEntidade Sgif.NOME_ENTIDADE not null,
  constraint pk_entidade_meio primary key(nomeEntidade)
);

create table Sgif.Meio (
  numMeio Sgif.NUM_MEIO not null,
  nomeMeio varchar(40) not null,
  nomeEntidade Sgif.NOME_ENTIDADE not null,
  constraint pk_meio primary key(numMeio,nomeEntidade),
  constraint fk_nome_entidade foreign key(nomeEntidade) references Sgif.EntidadeMeio(nomeEntidade) on delete cascade
);

create table Sgif.MeioCombate (
  numMeio Sgif.NUM_MEIO not null,
  nomeEntidade Sgif.NOME_ENTIDADE not null,
  constraint pk_meio_comabte primary key(numMeio,nomeEntidade),
  constraint fk_num_meio_nome_entidade foreign key(numMeio, nomeEntidade) references Sgif.Meio on delete cascade
);

create table Sgif.MeioApoio (
  numMeio Sgif.NUM_MEIO not null,
  nomeEntidade Sgif.NOME_ENTIDADE not null,
  constraint pk_meio_apoio primary key(numMeio,nomeEntidade),
  constraint fk_num_meio_nome_entidade foreign key(numMeio, nomeEntidade) references Sgif.Meio on delete cascade
);

create table Sgif.MeioSocorro (
  numMeio Sgif.NUM_MEIO not null,
  nomeEntidade Sgif.NOME_ENTIDADE not null,
  constraint pk_meio_socorro primary key(numMeio,nomeEntidade),
  constraint fk_num_meio_nome_entidade foreign key(numMeio, nomeEntidade) references Sgif.Meio on delete cascade
);

create table Sgif.Transporta (
  numMeio Sgif.NUM_MEIO not null,
  nomeEntidade Sgif.NOME_ENTIDADE not null,
  numvitimas smallint,
  numProcessoSocorro Sgif.NUM_PROCESSO_SOCORRO,
  constraint pk_transporta primary key(numMeio,nomeEntidade,numProcessoSocorro),
  constraint fk_num_meio_nome_entidade foreign key(numMeio, nomeEntidade) references Sgif.MeioSocorro on delete cascade,
	constraint fk_num_processo_socorro foreign key(numProcessoSocorro) references Sgif.ProcessoSocorro(numProcessoSocorro)
);

create table Sgif.Alocado (
  numMeio Sgif.NUM_MEIO not null,
  nomeEntidade Sgif.NOME_ENTIDADE not null,
  numHoras time,
  numProcessoSocorro Sgif.NUM_PROCESSO_SOCORRO,
  constraint pk_alocado primary key(numMeio, nomeEntidade, numProcessoSocorro),
  constraint fk_num_meio_nome_entidade foreign key(numMeio, nomeEntidade) references Sgif.MeioApoio on delete cascade,
  constraint fk_num_processo_socorro foreign key(numProcessoSocorro) references Sgif.ProcessoSocorro(numProcessoSocorro)
);
CREATE TRIGGER insert_alocado_trigger BEFORE INSERT ON Sgif.Alocado
FOR EACH row EXECUTE PROCEDURE Sgif.insert_alocado();

create table Sgif.Acciona (
  numMeio Sgif.NUM_MEIO not null,
  nomeEntidade Sgif.NOME_ENTIDADE not null,
  numProcessoSocorro Sgif.NUM_PROCESSO_SOCORRO,
  constraint pk_acciona primary key(numMeio, nomeEntidade, numProcessoSocorro),
  constraint fk_num_meio_nome_entidade foreign key(numMeio, nomeEntidade) references Sgif.Meio on delete cascade,
  constraint fk_num_processo_socorro foreign key(numProcessoSocorro) references Sgif.ProcessoSocorro(numProcessoSocorro)
);

create table Sgif.Coordenador (
  idCoordenador Sgif.ID_COORDENADOR,
  constraint pk_coordenador primary key(idCoordenador)
);

create table Sgif.Audita (
  idCoordenador Sgif.ID_COORDENADOR,
 	numMeio Sgif.NUM_MEIO,
 	nomeEntidade Sgif.NOME_ENTIDADE not null,
 	numProcessoSocorro Sgif.NUM_PROCESSO_SOCORRO,
 	dataHoraInicio Sgif.DATA_HORA_INICIO,
 	dataHoraFim timestamp,
 	dataAuditoria timestamp,
 	texto text,
  check(dataAuditoria > CURRENT_TIMESTAMP),
  check(dataHoraInicio <= dataHoraFim),
 	constraint pk_audita primary key(idCoordenador, numMeio, nomeEntidade, numProcessoSocorro),
 	constraint fk_num_meio_nome_entidade_processo_socorro foreign key(numMeio, nomeEntidade, numProcessoSocorro) references Sgif.Acciona on delete cascade,
 	constraint fk_id_coordenador foreign key(idCoordenador) references Sgif.Coordenador(idCoordenador)
);

create table Sgif.Solicita (
  idCoordenador Sgif.ID_COORDENADOR,
 	dataHoraInicioVideo Sgif.DATA_HORA_INICIO_VIDEO,
 	numCamara Sgif.NUM_CAMARA,
 	dataHoraInicio Sgif.DATA_HORA_INICIO,
 	dataHoraFim timestamp,
 	constraint pk_solicita primary key(idCoordenador,dataHoraInicioVideo,numCamara),
 	constraint fk_id_coordenador foreign key(idCoordenador) references Sgif.Coordenador(idCoordenador),
 	constraint fk_data_hora_inicio_num_camara foreign key(dataHoraInicioVideo, numCamara) references Sgif.Video
);
CREATE TRIGGER insert_solicita_trigger BEFORE INSERT ON Sgif.Solicita
FOR EACH row EXECUTE PROCEDURE Sgif.insert_solicita();
--- Keyvalue storage ---

create table keyvalues (
    key varchar(255) not null,
    value text not null,
    primary key (key)
);


--- Tag system ---

create table tagstore (
    tag varchar(255) not null,
    owner varchar(40) not null,
    content text not null,
    primary key (tag)
);

create unique index ix_tagstore_find on tagstore (lower(tag));
create index ix_tagstore_owner on tagstore (owner);


--- Discord message logging ---

create table discord_log (
    cid bigint not null,
    mid bigint not null,
    uid bigint not null,
    mtime timestamp not null,
    mdata text not null,
    etime timestamp,
    edata text,
    del boolean,
    primary key(cid, mid)
);

create table discord_file (
    cid bigint not null,
    mid bigint not null,
    file varchar not null,
    url varchar not null,
    size integer not null,
    primary key (cid, mid)
);

create index ix_discord_log_user on discord_log (uid);


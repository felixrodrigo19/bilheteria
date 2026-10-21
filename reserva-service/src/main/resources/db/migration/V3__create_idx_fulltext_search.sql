create extension if not exists unaccent;


create text search configuration pt_unaccent (copy = portuguese);

alter text search configuration pt_unaccent alter mapping for hword, hword_part, word with unaccent, portuguese_stem;

create index search_idx
    on evento
    using gin (
        to_tsvector(
            'pt_unaccent',
            coalesce(nome, '') || ' ' || coalesce(descricao, '')
        )
    );

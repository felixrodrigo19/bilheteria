-- ============================================================
-- Seed sintético do catálogo (laboratório de otimização)
-- Popula apenas o que a aplicação consome e atualiza: evento, sessao, setor, lote, assento, cupom.
-- Tabelas transacionais (reserva, item_reserva, ingresso, outbox...) ficam vazias.
-- Escala: env SEED_SCALE (1.0 ≈ 10M linhas; os testes usam 0.001)
-- ============================================================

SET LOCAL work_mem = '256MB';
SET LOCAL maintenance_work_mem = '1GB';
SET LOCAL synchronous_commit = off;

SELECT setseed(0.42);

CREATE FUNCTION pg_temp.sortear(opcoes text[]) RETURNS text
    LANGUAGE sql VOLATILE AS
$$
SELECT opcoes[1 + floor(random() * cardinality(opcoes))::int]
$$;

-- "A".."Z", "AA".."AZ", ...
CREATE FUNCTION pg_temp.fila(i int) RETURNS varchar(3)
    LANGUAGE sql IMMUTABLE AS
$$
SELECT CASE WHEN i < 26 THEN chr(65 + i) ELSE chr(64 + i / 26) || chr(65 + i % 26) END
$$;


-- ============================================================
-- Evento
-- ============================================================

-- Popularidade com cauda longa: poucos eventos concentram centenas de sessões, a maioria tem 1–5
CREATE TEMP TABLE seed_evento AS
SELECT n,
       uuidv7(criado_em - now())                    AS id,
       criado_em,
       1 + floor(power(random(), 12) * 130)::int    AS qtd_sessoes,
       random() < 0.03                              AS grande,
       (50 + floor(random() * 350)::int) * 100      AS preco_base
FROM (SELECT n, now() - random() * interval '730 days' AS criado_em
      FROM generate_series(1, greatest(1, round(5000 * ${seed_scale}))::int) n) e;

INSERT INTO evento (id, nome, descricao, local, criado_em)
SELECT id,
       pg_temp.sortear('{Show,Turnê,Festival,Stand-up,Peça,Musical,Concerto,Ópera,Balé,Tributo}') || ' ' ||
       pg_temp.sortear('{Banda,Orquestra,Coletivo,Trio,Companhia,Quarteto,Grupo,Duo}') || ' ' ||
       pg_temp.sortear('{Aurora,Vento Sul,Maré Alta,Cerrado,Ipê Roxo,Lua Nova,Sertão,Atlântico,Garoa,Mandacaru,Pôr do Sol,Rio Vermelho}'),
       CASE WHEN random() < 0.1 THEN NULL
            ELSE pg_temp.sortear('{Uma noite inesquecível,Apresentação única,Nova temporada,Edição especial,Turnê de despedida}') ||
                 ' com ' || pg_temp.sortear('{repertório clássico,convidados especiais,os maiores sucessos,músicas inéditas,elenco completo}') || '.'
       END,
       CASE WHEN grande
            THEN pg_temp.sortear('{Allianz Parque,Estádio do Morumbi,Arena MRV,Maracanã,Mineirão,Arena Fonte Nova}')
            ELSE pg_temp.sortear('{Teatro Municipal,Teatro Gazeta,Casa de Shows Vivo Rio,Espaço Unimed,Teatro Positivo,Auditório Ibirapuera,Teatro Guaíra,Circo Voador}')
       END || ' — ' ||
       pg_temp.sortear('{São Paulo/SP,Rio de Janeiro/RJ,Belo Horizonte/MG,Curitiba/PR,Porto Alegre/RS,Salvador/BA,Recife/PE,Fortaleza/CE,Brasília/DF,Goiânia/GO}'),
       criado_em
FROM seed_evento;


-- ============================================================
-- Sessão (de 6 meses atrás a 18 meses à frente)
-- ============================================================

CREATE TEMP TABLE seed_sessao AS
SELECT uuidv7(abre_vendas_em - interval '1 day' * (1 + floor(r_criacao * 30)) - now()) AS id,
       evento_id,
       inicio,
       abre_vendas_em,
       fecha_vendas_em,
       abre_vendas_em + (fecha_vendas_em - abre_vendas_em) * 0.8                      AS meia_reservada_ate,
       abre_vendas_em - interval '1 day' * (1 + floor(r_criacao * 30))                AS criado_em,
       CASE
           WHEN inicio < now() THEN CASE WHEN r_status < 0.95 THEN 'REALIZADA' ELSE 'CANCELADA' END
           WHEN now() < abre_vendas_em THEN CASE WHEN r_status < 0.9 THEN 'RASCUNHO' WHEN r_status < 0.95 THEN 'ADIADA' ELSE 'CANCELADA' END
           WHEN now() < fecha_vendas_em THEN CASE WHEN r_status < 0.9 THEN 'A_VENDA' WHEN r_status < 0.94 THEN 'ADIADA'
                                                  WHEN r_status < 0.97 THEN 'CANCELADA' ELSE 'VENDAS_ENCERRADAS' END
           ELSE 'VENDAS_ENCERRADAS'
       END::status_sessao                                                              AS status,
       grande,
       preco_base,
       CASE WHEN grande THEN 28 ELSE 8 END                                             AS filas,
       CASE WHEN grande THEN 12 ELSE 10 END                                            AS por_fila,
       CASE WHEN grande THEN 2000 ELSE 300 END                                         AS cap_pista,
       CASE WHEN grande THEN 500 ELSE 100 END                                          AS cap_premium
FROM (SELECT e.id                                                    AS evento_id,
             e.grande,
             e.preco_base,
             d.inicio,
             d.inicio - interval '1 day' * (60 + floor(random() * 240)) AS abre_vendas_em,
             d.inicio - interval '1 hour'                            AS fecha_vendas_em,
             random()                                                AS r_status,
             random()                                                AS r_criacao
      FROM seed_evento e
               CROSS JOIN LATERAL generate_series(1, e.qtd_sessoes) g
               CROSS JOIN LATERAL (SELECT date_trunc('day', now() - interval '180 days' + random() * interval '720 days')
                                              + make_interval(hours => 14 + floor(random() * 8)::int,
                                                              mins => floor(random() * 2)::int * 30) AS inicio
                                   WHERE g > 0) d) s;

INSERT INTO sessao (id, evento_id, inicio, status, abre_vendas_em, fecha_vendas_em,
                    capacidade, cota_cortesia, cota_meia, meia_reservada_ate, criado_em)
SELECT id,
       evento_id,
       inicio,
       status,
       abre_vendas_em,
       fecha_vendas_em,
       capacidade,
       floor(capacidade * 0.02)::int,
       floor(capacidade * 0.4)::int,
       meia_reservada_ate,
       criado_em
FROM (SELECT *, 2 * filas * por_fila + cap_pista + cap_premium AS capacidade FROM seed_sessao) s;


-- ============================================================
-- Setor: 2 numerados + 2 pistas por sessão
-- ============================================================

CREATE TEMP TABLE seed_setor AS
SELECT uuidv7()                                                         AS id,
       s.id                                                             AS sessao_id,
       v.nome,
       v.tipo::tipo_setor                                               AS tipo,
       CASE v.tipo WHEN 'NUMERADO' THEN s.filas * s.por_fila
                   ELSE CASE v.nome WHEN 'Pista' THEN s.cap_pista ELSE s.cap_premium END
       END                                                              AS capacidade,
       s.filas,
       s.por_fila,
       round(s.preco_base * v.multiplicador / 100) * 100                AS preco_base,
       s.abre_vendas_em,
       s.fecha_vendas_em
FROM seed_sessao s
         CROSS JOIN (VALUES ('Plateia A', 'NUMERADO', 1.5),
                            ('Plateia B', 'NUMERADO', 1.0),
                            ('Pista', 'PISTA', 0.8),
                            ('Pista Premium', 'PISTA', 2.0)) v(nome, tipo, multiplicador);

INSERT INTO setor (id, sessao_id, nome, tipo, capacidade)
SELECT id, sessao_id, nome, tipo, capacidade
FROM seed_setor;


-- ============================================================
-- Lote: 3 viradas por setor, preço subindo a cada virada
-- ============================================================

INSERT INTO lote (setor_id, ordem, preco_centavos, quantidade, vigente_ate)
SELECT st.id,
       l.ordem,
       round(st.preco_base * l.multiplicador / 100) * 100,
       CASE WHEN l.ordem < 3 THEN floor(st.capacidade * 0.3)::int
            ELSE st.capacidade - 2 * floor(st.capacidade * 0.3)::int
       END,
       CASE WHEN l.ordem < 3 THEN st.abre_vendas_em + (st.fecha_vendas_em - st.abre_vendas_em) * (0.3 * l.ordem) END
FROM seed_setor st
         CROSS JOIN (VALUES (1, 1.0), (2, 1.2), (3, 1.4)) l(ordem, multiplicador);


-- ============================================================
-- Assento: só setores numerados
-- ============================================================

INSERT INTO assento (setor_id, fila, numero, tipo, status)
SELECT st.id,
       pg_temp.fila(f),
       n,
       CASE WHEN r < 0.01 THEN 'CADEIRANTE' WHEN r < 0.02 THEN 'ACOMPANHANTE' ELSE 'COMUM' END::tipo_assento,
       CASE WHEN random() < 0.005 THEN 'INDISPONIVEL' ELSE 'DISPONIVEL' END::status_assento
FROM seed_setor st
         CROSS JOIN LATERAL generate_series(0, st.filas - 1) f
         CROSS JOIN LATERAL generate_series(1, st.por_fila) n
         CROSS JOIN LATERAL (SELECT random() AS r WHERE n > 0) x
WHERE st.tipo = 'NUMERADO';


-- ============================================================
-- Cupom: ~70% amarrados a um evento, janelas vencidas, vigentes e futuras
-- ============================================================

INSERT INTO cupom (codigo, evento_id, tipo, valor, valido_de, valido_ate, limite_usos, limite_por_cliente)
SELECT pg_temp.sortear('{PROMO,VIP,FESTA,BLACK,AMIGO,ESTREIA}') || lpad(to_hex(c.n), 6, '0') || upper(substr(md5(c.n::text), 1, 6)),
       e.id,
       CASE WHEN c.percentual THEN 'PERCENTUAL' ELSE 'FIXO' END::tipo_cupom,
       CASE WHEN c.percentual THEN 5 + floor(random() * 46) ELSE (2 + floor(random() * 9)) * 500 END,
       c.valido_de,
       c.valido_de + interval '1 day' * (7 + floor(random() * 84)),
       (1 + floor(random() * 100)::int) * 50,
       CASE WHEN random() < 0.8 THEN 1 ELSE 2 + floor(random() * 3) END
FROM (SELECT n,
             random() < 0.6                                           AS percentual,
             now() - interval '400 days' + random() * interval '500 days' AS valido_de,
             CASE WHEN random() < 0.7 THEN 1 + floor(random() * (SELECT count(*) FROM seed_evento))::int END AS evento_n
      FROM generate_series(1, greatest(1, round(50000 * ${seed_scale}))::int) n) c
         LEFT JOIN seed_evento e ON e.n = c.evento_n;


DROP TABLE seed_setor, seed_sessao, seed_evento;
DROP FUNCTION pg_temp.sortear(text[]), pg_temp.fila(int);

ANALYZE evento, sessao, setor, lote, assento, cupom;

-- ============================================================
-- Laboratório de otimização sobre o seed do catálogo (V2__seed_catalogo.sql)
-- Rode cada consulta com EXPLAIN (ANALYZE, BUFFERS) antes e depois de cada mudança.
-- Habilite pg_stat_statements para medir a carga como um todo.
-- ============================================================


-- 1. Vitrine: sessões à venda nos próximos 30 dias com o menor preço vigente
-- Dica: idx_sessao_a_venda cobre o filtro, mas setor(sessao_id) só é atendido pelo UNIQUE (sessao_id, nome)
-- e lote(setor_id) pelo UNIQUE (setor_id, ordem). Compare com índices cobrindo e com uma materialized view.
SELECT e.nome, e.local, s.inicio, min(l.preco_centavos) AS a_partir_de
FROM sessao s
         JOIN evento e ON e.id = s.evento_id
         JOIN setor st ON st.sessao_id = s.id
         JOIN lote l ON l.setor_id = st.id
WHERE s.status = 'A_VENDA'
  AND s.inicio BETWEEN now() AND now() + interval '30 days'
  AND (l.vigente_ate IS NULL OR l.vigente_ate > now())
GROUP BY e.nome, e.local, s.inicio
ORDER BY s.inicio
LIMIT 50;


-- 2. Mapa de assentos de uma sessão (~9,4M linhas em assento)
-- Dica: o UNIQUE (setor_id, fila, numero) permite index-only scan? Veja "Heap Fetches" e o efeito do VACUUM.
SELECT st.nome, a.fila, a.numero, a.tipo, a.status
FROM setor st
         JOIN assento a ON a.setor_id = st.id
WHERE st.sessao_id = (SELECT id FROM sessao WHERE status = 'A_VENDA' ORDER BY id LIMIT 1)
ORDER BY st.nome, a.fila, a.numero;


-- 3. Disponibilidade por setor
-- Dica: count em assento vs. capacidade - vendidos no setor. Teste índice parcial WHERE status = 'DISPONIVEL'.
SELECT st.id, st.nome, count(*) FILTER (WHERE a.status = 'DISPONIVEL') AS disponiveis
FROM setor st
         JOIN assento a ON a.setor_id = st.id
WHERE st.sessao_id IN (SELECT id FROM sessao WHERE status = 'A_VENDA' LIMIT 100)
GROUP BY st.id, st.nome;


-- 4. Lote vigente por setor: DISTINCT ON vs. LATERAL
SELECT DISTINCT ON (l.setor_id) l.setor_id, l.ordem, l.preco_centavos
FROM lote l
WHERE (l.vigente_ate IS NULL OR l.vigente_ate > now())
  AND l.vendidos < l.quantidade
ORDER BY l.setor_id, l.ordem;

SELECT st.id, v.ordem, v.preco_centavos
FROM setor st
         CROSS JOIN LATERAL (SELECT ordem, preco_centavos
                             FROM lote
                             WHERE setor_id = st.id
                               AND (vigente_ate IS NULL OR vigente_ate > now())
                               AND vendidos < quantidade
                             ORDER BY ordem
                             LIMIT 1) v
WHERE st.sessao_id IN (SELECT id FROM sessao WHERE status = 'A_VENDA' LIMIT 100);


-- 5. Cupons vigentes de um evento
-- Dica: cupom(evento_id) não tem índice. Compare btree (evento_id, valido_ate) com índice parcial.
SELECT codigo, tipo, valor, valido_ate
FROM cupom
WHERE evento_id = (SELECT evento_id FROM sessao GROUP BY evento_id ORDER BY count(*) DESC LIMIT 1)
  AND now() BETWEEN valido_de AND valido_ate
  AND usos < limite_usos;


-- 6. Concorrência: bloquear assentos de uma sessão quente (evento com mais sessões)
-- Dica: rode com pgbench -c 50 -f arquivo.sql e compare FOR UPDATE, FOR UPDATE SKIP LOCKED
-- e o update otimista por version. Observe pg_locks e pg_stat_activity.wait_event.
BEGIN;
SELECT a.id
FROM assento a
         JOIN setor st ON st.id = a.setor_id
WHERE st.sessao_id = (SELECT id FROM sessao WHERE status = 'A_VENDA' ORDER BY id LIMIT 1)
  AND a.status = 'DISPONIVEL'
ORDER BY a.fila, a.numero
LIMIT 4
FOR UPDATE SKIP LOCKED;
ROLLBACK;

-- Update otimista (o que o JPA @Version faz)
-- UPDATE assento SET status = 'BLOQUEADO', version = version + 1 WHERE id = :id AND version = :version;


-- 7. Bloat: depois de muitos updates no laboratório 6, meça e limpe
SELECT relname, n_live_tup, n_dead_tup, last_autovacuum
FROM pg_stat_user_tables
WHERE relname IN ('assento', 'lote', 'setor', 'sessao')
ORDER BY n_dead_tup DESC;
-- VACUUM (VERBOSE, ANALYZE) assento;  -- não roda dentro da migration do Flyway, só aqui

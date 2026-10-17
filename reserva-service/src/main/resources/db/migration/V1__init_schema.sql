-- ============================================================
-- Tipos
-- ============================================================

CREATE TYPE status_sessao AS ENUM
( 'RASCUNHO',
    'A_VENDA',
    'VENDAS_ENCERRADAS',
    'REALIZADA',
    'CANCELADA',
    'ADIADA');
CREATE TYPE tipo_setor AS ENUM
( 'NUMERADO',
    'PISTA');
CREATE TYPE tipo_cupom AS ENUM
( 'PERCENTUAL',
    'FIXO');
CREATE TYPE status_reserva AS ENUM
( 'PENDENTE_PAGAMENTO',
    'CONFIRMADA',
    'CANCELADA',
    'EXPIRADA');
CREATE TYPE status_reembolso AS ENUM
( 'SOLICITADO',
    'EFETUADO',
    'FALHOU');
CREATE TYPE tipo_assento AS ENUM
( 'COMUM',
    'CADEIRANTE',
    'ACOMPANHANTE');
CREATE TYPE status_assento AS ENUM
( 'DISPONIVEL',
    'BLOQUEADO',
    'VENDIDO',
    'INDISPONIVEL');
CREATE TYPE tipo_ingresso AS ENUM
( 'INTEIRA',
    'MEIA',
    'CORTESIA');
CREATE TYPE status_ingresso AS ENUM
( 'EMITIDO',
    'UTILIZADO',
    'CANCELADO',
    'SUBSTITUIDO');


-- ============================================================
-- Catálogo
-- ============================================================

CREATE TABLE evento
(
    id        uuid PRIMARY KEY DEFAULT uuidv7(),
    nome      varchar(200) NOT NULL,
    descricao text,
    local     varchar(200) NOT NULL,
    criado_em timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE sessao
(
    id                 uuid PRIMARY KEY DEFAULT uuidv7(),
    evento_id          uuid          NOT NULL REFERENCES evento (id),
    inicio             timestamptz   NOT NULL,
    status             status_sessao NOT NULL DEFAULT 'RASCUNHO',
    abre_vendas_em     timestamptz   NOT NULL,
    fecha_vendas_em    timestamptz   NOT NULL,
    capacidade         integer       NOT NULL,
    cota_cortesia      integer       NOT NULL DEFAULT 0,
    cortesias_emitidas integer       NOT NULL DEFAULT 0,
    vendidos           integer       NOT NULL DEFAULT 0,
    cota_meia          integer       NOT NULL,
    meias_vendidas     integer       NOT NULL DEFAULT 0,
    meia_reservada_ate timestamptz   NOT NULL,
    criado_em          timestamptz   NOT NULL DEFAULT now(),
    version            bigint        NOT NULL DEFAULT 0
);

CREATE INDEX idx_sessao_evento ON sessao (evento_id);
CREATE INDEX idx_sessao_a_venda ON sessao (inicio) WHERE status = 'A_VENDA';

CREATE TABLE setor
(
    id         uuid PRIMARY KEY DEFAULT uuidv7(),
    sessao_id  uuid        NOT NULL REFERENCES sessao (id),
    nome       varchar(60) NOT NULL,
    tipo       tipo_setor  NOT NULL,
    capacidade integer     NOT NULL,
    vendidos   integer     NOT NULL DEFAULT 0,
    UNIQUE (sessao_id, nome)
);

CREATE TABLE lote
(
    id             uuid PRIMARY KEY DEFAULT uuidv7(),
    setor_id       uuid     NOT NULL REFERENCES setor (id),
    ordem          smallint NOT NULL,
    preco_centavos bigint   NOT NULL,
    quantidade     integer  NOT NULL,
    vendidos       integer  NOT NULL DEFAULT 0,
    vigente_ate    timestamptz,
    UNIQUE (setor_id, ordem)
);

CREATE TABLE cupom
(
    id                 uuid PRIMARY KEY DEFAULT uuidv7(),
    codigo             varchar(30) NOT NULL UNIQUE,
    evento_id          uuid REFERENCES evento (id),
    tipo               tipo_cupom  NOT NULL,
    valor              bigint      NOT NULL,
    valido_de          timestamptz NOT NULL,
    valido_ate         timestamptz NOT NULL,
    limite_usos        integer     NOT NULL,
    usos               integer     NOT NULL DEFAULT 0,
    limite_por_cliente smallint    NOT NULL DEFAULT 1
);


-- ============================================================
-- Venda
-- ============================================================

CREATE TABLE reserva
(
    id                   uuid PRIMARY KEY DEFAULT uuidv7(),
    cliente_id           uuid           NOT NULL,
    sessao_id            uuid           NOT NULL REFERENCES sessao (id),
    status               status_reserva NOT NULL DEFAULT 'PENDENTE_PAGAMENTO',
    cupom_id             uuid REFERENCES cupom (id),
    desconto_centavos    bigint         NOT NULL DEFAULT 0,
    taxa_centavos        bigint         NOT NULL DEFAULT 0,
    valor_total_centavos bigint         NOT NULL,
    reembolso_status     status_reembolso,
    expira_em            timestamptz    NOT NULL,
    criado_em            timestamptz    NOT NULL DEFAULT now(),
    confirmada_em        timestamptz,
    version              bigint         NOT NULL DEFAULT 0
);

-- Uma pendente por cliente e sessão: barra o segundo POST simultâneo e tira a corrida do limite por CPF
CREATE UNIQUE INDEX uq_reserva_uma_pendente
    ON reserva (cliente_id, sessao_id) WHERE status = 'PENDENTE_PAGAMENTO';

CREATE INDEX idx_reserva_expiracao ON reserva (expira_em) WHERE status = 'PENDENTE_PAGAMENTO';
CREATE INDEX idx_reserva_cliente ON reserva (cliente_id, criado_em DESC);
CREATE INDEX idx_reserva_sessao ON reserva (sessao_id, status);

CREATE TABLE assento
(
    id         uuid PRIMARY KEY DEFAULT uuidv7(),
    setor_id   uuid           NOT NULL REFERENCES setor (id),
    fila       varchar(3)     NOT NULL, -- "A", "K", "AA"
    numero     smallint       NOT NULL,
    tipo       tipo_assento   NOT NULL DEFAULT 'COMUM',
    status     status_assento NOT NULL DEFAULT 'DISPONIVEL',
    reserva_id uuid REFERENCES reserva (id),
    version    bigint         NOT NULL DEFAULT 0,
    UNIQUE (setor_id, fila, numero)
);

CREATE INDEX idx_assento_reserva ON assento (reserva_id) WHERE reserva_id IS NOT NULL;

CREATE TABLE item_reserva
(
    id                uuid PRIMARY KEY DEFAULT uuidv7(),
    reserva_id        uuid          NOT NULL REFERENCES reserva (id),
    setor_id          uuid          NOT NULL REFERENCES setor (id),
    assento_id        uuid REFERENCES assento (id),
    lote_id           uuid          NOT NULL REFERENCES lote (id),
    tipo              tipo_ingresso NOT NULL,
    preco_centavos    bigint        NOT NULL,
    desconto_centavos bigint        NOT NULL DEFAULT 0,
    taxa_centavos     bigint        NOT NULL DEFAULT 0,
    titular_nome      varchar(150)  NOT NULL,
    titular_cpf       char(11)      NOT NULL,
    UNIQUE (reserva_id, assento_id)
);

-- Cada meia do pedido tem um beneficiário diferente
CREATE UNIQUE INDEX uq_item_meia_titular
    ON item_reserva (reserva_id, titular_cpf) WHERE tipo = 'MEIA';

CREATE TABLE ingresso
(
    id              uuid PRIMARY KEY DEFAULT uuidv7(),
    codigo          varchar(64)     NOT NULL UNIQUE,
    sessao_id       uuid            NOT NULL REFERENCES sessao (id),
    setor_id        uuid            NOT NULL REFERENCES setor (id),
    assento_id      uuid REFERENCES assento (id),
    item_reserva_id uuid REFERENCES item_reserva (id),
    cliente_id      uuid,
    tipo            tipo_ingresso   NOT NULL,
    titular_nome    varchar(150)    NOT NULL,
    titular_cpf     char(11)        NOT NULL,
    status          status_ingresso NOT NULL DEFAULT 'EMITIDO',
    substitui_id    uuid UNIQUE REFERENCES ingresso (id),
    emitido_em      timestamptz     NOT NULL DEFAULT now(),
    utilizado_em    timestamptz,
    version         bigint          NOT NULL DEFAULT 0
);

-- Um ingresso válido por assento. Na transferência, marque o antigo SUBSTITUIDO antes de inserir o novo.
CREATE UNIQUE INDEX uq_ingresso_assento_valido
    ON ingresso (assento_id) WHERE status IN ('EMITIDO', 'UTILIZADO');

-- Um beneficiário não leva duas meias para a mesma sessão, nem em pedidos diferentes
CREATE UNIQUE INDEX uq_ingresso_meia_titular
    ON ingresso (sessao_id, titular_cpf) WHERE tipo = 'MEIA' AND status IN ('EMITIDO', 'UTILIZADO');

CREATE INDEX idx_ingresso_item ON ingresso (item_reserva_id);
CREATE INDEX idx_ingresso_cliente ON ingresso (cliente_id) WHERE cliente_id IS NOT NULL;


-- ============================================================
-- Infraestrutura: outbox e idempotência
-- ============================================================

CREATE TABLE outbox_evento
(
    id           uuid PRIMARY KEY,
    agregado_id  uuid        NOT NULL,
    tipo         varchar(60) NOT NULL,
    payload      jsonb       NOT NULL,
    criado_em    timestamptz NOT NULL DEFAULT now(),
    publicado_em timestamptz
);

-- O publicador lê só as pendentes, na ordem do uuid v7
CREATE INDEX idx_outbox_pendente ON outbox_evento (id) WHERE publicado_em IS NULL;

CREATE TABLE idempotencia
(
    cliente_id      uuid         NOT NULL,
    chave           varchar(100) NOT NULL,
    hash_requisicao char(64)     NOT NULL,
    status_http     smallint,
    resposta        jsonb,
    criado_em       timestamptz  NOT NULL DEFAULT now(),
    PRIMARY KEY (cliente_id, chave)
);

CREATE INDEX idx_idempotencia_limpeza ON idempotencia (criado_em);

CREATE TABLE mensagem_processada
(
    event_id      uuid PRIMARY KEY,
    processado_em timestamptz NOT NULL DEFAULT now()
);
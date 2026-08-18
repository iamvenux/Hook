-- ─────────────────────────────────────────────
-- Hook — Schema inicial do banco de dados (MySQL)
-- Escopo: reboque (leve/pesado), cliente e motorista,
-- pagamento Pix/Dinheiro, avaliação só com nota.
-- ─────────────────────────────────────────────

CREATE DATABASE IF NOT EXISTS hook_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE hook_db;

-- ─────────────────────────────────────────────
-- usuarios — clientes e motoristas na mesma tabela,
-- diferenciados pela coluna `tipo`.
-- ─────────────────────────────────────────────
CREATE TABLE usuarios (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome          VARCHAR(120)      NOT NULL,
  email         VARCHAR(150)      NOT NULL UNIQUE,
  senha_hash    VARCHAR(255)      NOT NULL,
  tipo          ENUM('cliente', 'motorista') NOT NULL,
  telefone      VARCHAR(20)       NULL,

  -- só usado quando tipo = 'motorista'
  placa_guincho VARCHAR(10)       NULL,
  disponivel    TINYINT(1)        NOT NULL DEFAULT 0,
  latitude_atual  DECIMAL(10, 7)  NULL,
  longitude_atual DECIMAL(10, 7)  NULL,

  api_token     VARCHAR(64)       NULL,
  created_at    DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME          NULL ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_usuarios_tipo (tipo),
  INDEX idx_usuarios_api_token (api_token)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────
-- veiculos — um cliente pode ter vários veículos
-- ─────────────────────────────────────────────
CREATE TABLE veiculos (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  usuario_id   INT UNSIGNED      NOT NULL,
  tipo         ENUM('Carro', 'Moto', 'SUV') NOT NULL DEFAULT 'Carro',
  marca        VARCHAR(60)       NOT NULL,
  modelo       VARCHAR(60)       NOT NULL,
  ano          SMALLINT UNSIGNED NULL,
  placa        VARCHAR(10)       NOT NULL,
  cor          VARCHAR(30)       NULL,
  created_at   DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_veiculos_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    ON DELETE CASCADE,

  INDEX idx_veiculos_usuario (usuario_id)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────
-- solicitacoes — cada pedido de reboque
-- ─────────────────────────────────────────────
CREATE TABLE solicitacoes (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cliente_id      INT UNSIGNED  NOT NULL,
  motorista_id    INT UNSIGNED  NULL,
  veiculo_id      INT UNSIGNED  NOT NULL,

  tipo_reboque    ENUM('Guincho Leve', 'Guincho Pesado') NOT NULL,
  forma_pagamento ENUM('Pix', 'Dinheiro') NOT NULL,

  endereco        VARCHAR(255)  NOT NULL,
  latitude        DECIMAL(10, 7) NOT NULL,
  longitude       DECIMAL(10, 7) NOT NULL,

  valor_estimado  DECIMAL(10, 2) NOT NULL,

  status          ENUM('buscando', 'aceito', 'a_caminho', 'concluido', 'cancelado')
                  NOT NULL DEFAULT 'buscando',

  created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME      NULL ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT fk_solicitacoes_cliente
    FOREIGN KEY (cliente_id) REFERENCES usuarios(id),
  CONSTRAINT fk_solicitacoes_motorista
    FOREIGN KEY (motorista_id) REFERENCES usuarios(id),
  CONSTRAINT fk_solicitacoes_veiculo
    FOREIGN KEY (veiculo_id) REFERENCES veiculos(id),

  INDEX idx_solicitacoes_status (status),
  INDEX idx_solicitacoes_cliente (cliente_id),
  INDEX idx_solicitacoes_motorista (motorista_id)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────
-- avaliacoes — uma nota (1 a 5) por solicitação concluída
-- ─────────────────────────────────────────────
CREATE TABLE avaliacoes (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  solicitacao_id  INT UNSIGNED  NOT NULL UNIQUE,
  nota            TINYINT UNSIGNED NOT NULL,
  created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_avaliacoes_solicitacao
    FOREIGN KEY (solicitacao_id) REFERENCES solicitacoes(id)
    ON DELETE CASCADE,

  CONSTRAINT chk_nota CHECK (nota BETWEEN 1 AND 5)
) ENGINE=InnoDB;

-- ============================================================
-- Migração: perfil (endereços salvos + forma de pagamento padrão)
-- Data: 11/11/2026
--
-- Rode este arquivo em quem JÁ TEM o hook_db criado:
--   C:\xampp\mysql\bin\mysql.exe -u root hook_db < 2026-11-11_perfil.sql
--
-- Quem for criar o banco do zero não precisa: o hook_db.sql
-- já vem com estas mudanças.
-- ============================================================

ALTER TABLE `usuarios`
  ADD COLUMN `forma_pagamento_padrao` enum('Pix','Dinheiro') NOT NULL DEFAULT 'Pix'
  AFTER `tipo_guincho`;

CREATE TABLE `enderecos` (
  `id` int(10) UNSIGNED NOT NULL,
  `usuario_id` int(10) UNSIGNED NOT NULL,
  `apelido` varchar(40) NOT NULL,
  `endereco` varchar(255) NOT NULL,
  `latitude` decimal(10,7) NOT NULL,
  `longitude` decimal(10,7) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE `enderecos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_enderecos_usuario` (`usuario_id`);

ALTER TABLE `enderecos`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

ALTER TABLE `enderecos`
  ADD CONSTRAINT `fk_enderecos_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

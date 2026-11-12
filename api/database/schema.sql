-- MASTER: LabES_SistemaMIAR_1011.pdf, pagina 25. Nove entidades.
CREATE TABLE IF NOT EXISTS "USUARIO" (
 id_usuario integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 nome text NOT NULL, email text NOT NULL UNIQUE, senha text NOT NULL,
 telefone text NOT NULL, documento text,
 tipo_usuario text NOT NULL CHECK (tipo_usuario IN ('Cidadão','Protetor independente','ONG')),
 ativo boolean NOT NULL DEFAULT true
);
CREATE TABLE IF NOT EXISTS "ESPECIE" (
 id_especie integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY, nome text NOT NULL
);
CREATE TABLE IF NOT EXISTS "ANIMAL" (
 id_animal integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 id_especie integer NOT NULL REFERENCES "ESPECIE",
 nome text, porte text NOT NULL CHECK (porte IN ('Pequeno','Médio','Grande')),
 descricao text NOT NULL, idade text, genero text, cor text, url_foto text,
 data_cadastro date NOT NULL DEFAULT CURRENT_DATE
);
CREATE TABLE IF NOT EXISTS "OCORRENCIA_ANIMAL" (
 id_ocorrencia integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 id_usuario_responsavel integer NOT NULL REFERENCES "USUARIO",
 id_animal integer NOT NULL REFERENCES "ANIMAL",
 status_ocorrencia text NOT NULL CHECK (status_ocorrencia IN ('Perdido','Encontrado','Emergência','Aguardando Adoção','Adotado','Resgatado')),
 descricao text NOT NULL, data_registro date NOT NULL DEFAULT CURRENT_DATE
);
CREATE TABLE IF NOT EXISTS "CIDADE" (
 id_cidade integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY, nome text NOT NULL, estado text
);
CREATE TABLE IF NOT EXISTS "LOCALIZACAC" (
 id_localizacao integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 id_ocorrencia integer NOT NULL UNIQUE REFERENCES "OCORRENCIA_ANIMAL" ON DELETE CASCADE,
 id_cidade integer NOT NULL REFERENCES "CIDADE",
 latitude double precision NOT NULL CHECK (latitude BETWEEN -90 AND 90),
 longitude double precision NOT NULL CHECK (longitude BETWEEN -180 AND 180), endereco text
);
CREATE TABLE IF NOT EXISTS "FOTO" (
 id_foto integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 id_ocorrencia integer NOT NULL REFERENCES "OCORRENCIA_ANIMAL" ON DELETE CASCADE,
 url_storage text NOT NULL, descricao text, data_upload date NOT NULL DEFAULT CURRENT_DATE
);
CREATE TABLE IF NOT EXISTS "CONTATO" (
 id_contato integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 id_ocorrencia integer NOT NULL REFERENCES "OCORRENCIA_ANIMAL" ON DELETE CASCADE,
 numero_whatsapp text NOT NULL, whatsapp_link text NOT NULL, data_contato date
);
CREATE TABLE IF NOT EXISTS "MENSAGEM_WHATSAPP" (
 id_mensagem integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 id_contato integer NOT NULL REFERENCES "CONTATO" ON DELETE CASCADE,
 texto text, data_envio date, remetente text
);
CREATE INDEX IF NOT EXISTS ocorrencia_status ON "OCORRENCIA_ANIMAL"(status_ocorrencia);
CREATE INDEX IF NOT EXISTS ocorrencia_responsavel ON "OCORRENCIA_ANIMAL"(id_usuario_responsavel);
CREATE INDEX IF NOT EXISTS animal_especie_porte ON "ANIMAL"(id_especie,porte);
CREATE UNIQUE INDEX IF NOT EXISTS especie_nome ON "ESPECIE"(lower(nome));
CREATE UNIQUE INDEX IF NOT EXISTS cidade_nome_estado ON "CIDADE"(lower(nome),lower(COALESCE(estado,'')));
CREATE INDEX IF NOT EXISTS localizacao_cidade ON "LOCALIZACAC"(id_cidade);
CREATE INDEX IF NOT EXISTS fotos_ocorrencia ON "FOTO"(id_ocorrencia);
CREATE INDEX IF NOT EXISTS contatos_ocorrencia ON "CONTATO"(id_ocorrencia);

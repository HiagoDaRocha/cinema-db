-- 0. Definição de Tipos Enumerados (Enums)
CREATE TYPE filme_status AS ENUM ('alta', 'cartaz', 'breve');
CREATE TYPE assento_status AS ENUM ('livre', 'reservado', 'ocupado');
CREATE TYPE metodo_pagamento AS ENUM ('pix', 'credito', 'debito');
CREATE TYPE ingresso_tipo AS ENUM ('inteira', 'meia');
CREATE TYPE produto_categoria AS ENUM ('pipoca', 'doce', 'bebida', 'combo');

-- 1. Tabelas de Localização
CREATE TABLE estados (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    sigla CHAR(2) NOT NULL UNIQUE,
    nome VARCHAR(100) NOT NULL
);

CREATE TABLE cidades (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    estado_id UUID NOT NULL REFERENCES estados(id) ON DELETE CASCADE,
    nome VARCHAR(100) NOT NULL
);

-- 2. Catálogo e Estrutura de Cinema
CREATE TABLE cinemas (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    nome VARCHAR(255) NOT NULL,
    cidade_id UUID NOT NULL REFERENCES cidades(id),
    endereco TEXT NOT NULL
);

CREATE TABLE filmes (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    titulo VARCHAR(255) NOT NULL,
    sinopse TEXT,
    duracao INT NOT NULL, -- em minutos
    classificacao VARCHAR(10),
    status filme_status DEFAULT 'breve'
);

CREATE TABLE sessoes (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    movie_id UUID NOT NULL REFERENCES filmes(id),
    cinema_id UUID NOT NULL REFERENCES cinemas(id),
    sala_tipo VARCHAR(50) NOT NULL, -- ex: 'IMAX', '3D'
    audio_tipo VARCHAR(50) NOT NULL, -- ex: 'Dublado', 'Legendado'
    data_hora TIMESTAMP NOT NULL,
    preco_base DECIMAL(10,2) NOT NULL
);

-- 3. Gestão de Assentos
CREATE TABLE assentos (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    session_id UUID NOT NULL REFERENCES sessoes(id) ON DELETE CASCADE,
    fila CHAR(1) NOT NULL,
    numero INT NOT NULL,
    status assento_status DEFAULT 'livre',
    -- Garante que não existam dois assentos iguais na mesma sessão
    UNIQUE(session_id, fila, numero) 
);

-- 4. Usuários e Vendas
CREATE TABLE usuarios (
    id UUID PRIMARY KEY, -- Aqui o ID vem do Keycloak, não geramos default
    nome VARCHAR(100) NOT NULL,
    sobrenome VARCHAR(100) NOT NULL,
    cpf VARCHAR(11) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    telefone VARCHAR(20)
);

CREATE TABLE pedidos (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id UUID NOT NULL REFERENCES usuarios(id),
    total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status_pagamento VARCHAR(50) DEFAULT 'pendente',
    data_compra TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE pagamentos (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    pedido_id UUID NOT NULL UNIQUE REFERENCES pedidos(id),
    metodo metodo_pagamento NOT NULL,
    status VARCHAR(50),
    data_processamento TIMESTAMP
);

-- 5. Itens do Pedido (Ingressos e Comida)
CREATE TABLE produtos (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    nome VARCHAR(255) NOT NULL,
    preco DECIMAL(10,2) NOT NULL,
    categoria produto_categoria NOT NULL
);

CREATE TABLE ingressos (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    pedido_id UUID NOT NULL REFERENCES pedidos(id),
    seat_id UUID NOT NULL REFERENCES assentos(id),
    tipo ingresso_tipo NOT NULL,
    preco_final DECIMAL(10,2) NOT NULL
);

CREATE TABLE pedido_produtos (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    pedido_id UUID NOT NULL REFERENCES pedidos(id),
    produto_id UUID NOT NULL REFERENCES produtos(id),
    quantidade INT NOT NULL CHECK (quantidade > 0),
    preco_unitario DECIMAL(10,2) NOT NULL -- Histórico do preço no momento da venda
);

-- Índices para otimização de busca
CREATE INDEX idx_sessoes_data ON sessoes(data_hora);
CREATE INDEX idx_assentos_sessao ON assentos(session_id);
CREATE INDEX idx_pedidos_usuario ON pedidos(user_id);
# TODO: Integração brcobranca + boleto_cnab_api

> Plano detalhado para simplificar e integrar os dois projetos
>
> **Autor:** Maxwell Oliveira (@maxwbh)
> **Data:** 2025-12-31
> **Versão brcobranca:** 12.2.0

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura Proposta](#arquitetura-proposta)
3. [TODO brcobranca](#todo-brcobranca)
4. [TODO boleto_cnab_api](#todo-boleto_cnab_api)
5. [Cronograma Sugerido](#cronograma-sugerido)
6. [Guia de Migração](#guia-de-migração)

---

## Visão Geral

### Situação Atual

```
┌─────────────────────────────────────────────────────────────┐
│                    boleto_cnab_api                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Grape API + Código duplicado de mapeamento           │  │
│  │  - Mapeia campos manualmente                          │  │
│  │  - Converte datas manualmente                         │  │
│  │  - Monta respostas campo por campo                    │  │
│  └───────────────────────────────────────────────────────┘  │
│                           │                                 │
│                           ▼                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   brcobranca                          │  │
│  │  - Boletos, Remessa, Retorno                          │  │
│  │  - Sem API de serialização (até v12.1.0)              │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Situação Proposta

```
┌─────────────────────────────────────────────────────────────┐
│                    boleto_cnab_api                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Grape API (apenas roteamento e HTTP)                 │  │
│  │  - Usa to_hash/as_json do brcobranca                  │  │
│  │  - Sem duplicação de código                           │  │
│  │  - Foco em HTTP, logging, deploy                      │  │
│  └───────────────────────────────────────────────────────┘  │
│                           │                                 │
│                           ▼                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                brcobranca v12.2.0+                    │  │
│  │  - to_hash, as_json, to_json (✅ IMPLEMENTADO)        │  │
│  │  - dados_calculados, dados_entrada (✅ IMPLEMENTADO)  │  │
│  │  - Remessa#to_hash (🔄 A FAZER)                       │  │
│  │  - Retorno#to_hash (🔄 A FAZER)                       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Arquitetura Proposta

### Responsabilidades

| Camada | Projeto | Responsabilidade |
|--------|---------|------------------|
| **Core** | brcobranca | Cálculos, validações, geração de arquivos, serialização |
| **API** | boleto_cnab_api | HTTP, JSON I/O, logging, autenticação, deploy |

### Fluxo de Dados

```
Request HTTP
     │
     ▼
┌─────────────────┐
│ boleto_cnab_api │ ──► Validação de parâmetros HTTP
│   (Grape API)   │ ──► Logging de requisição
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   brcobranca    │ ──► Criação do objeto (Boleto/Remessa/Retorno)
│     (Gem)       │ ──► Validação de negócio
│                 │ ──► Cálculos (código barras, linha digitável, etc)
│                 │ ──► Serialização (to_hash/as_json)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ boleto_cnab_api │ ──► Formatação da resposta HTTP
│   (Grape API)   │ ──► Logging de resposta
└────────┬────────┘
         │
         ▼
Response HTTP (JSON/PDF/etc)
```

---

## TODO brcobranca

### Fase 1: Boleto API (✅ CONCLUÍDO em v12.2.0)

- [x] **1.1** Implementar `Boleto::Base#to_hash`
  - Arquivo: `lib/brcobranca/boleto/base.rb`
  - Status: ✅ Concluído
  - Descrição: Retorna todos os dados do boleto como Hash

- [x] **1.2** Implementar `Boleto::Base#as_json`
  - Arquivo: `lib/brcobranca/boleto/base.rb`
  - Status: ✅ Concluído
  - Descrição: Hash com chaves string para JSON

- [x] **1.3** Implementar `Boleto::Base#to_json`
  - Arquivo: `lib/brcobranca/boleto/base.rb`
  - Status: ✅ Concluído
  - Descrição: String JSON

- [x] **1.4** Implementar `Boleto::Base#dados_entrada`
  - Arquivo: `lib/brcobranca/boleto/base.rb`
  - Status: ✅ Concluído
  - Descrição: Campos informados pelo usuário

- [x] **1.5** Implementar `Boleto::Base#dados_calculados`
  - Arquivo: `lib/brcobranca/boleto/base.rb`
  - Status: ✅ Concluído
  - Descrição: Campos gerados (código barras, linha digitável, etc)

- [x] **1.6** Implementar `Boleto::Base#dados_pix`
  - Arquivo: `lib/brcobranca/boleto/base.rb`
  - Status: ✅ Concluído
  - Descrição: Dados PIX quando EMV disponível

---

### Fase 2: Melhorias de Validação (🔄 A FAZER)

- [ ] **2.1** Criar método `valido?` sem exceção
  ```ruby
  # Arquivo: lib/brcobranca/boleto/base.rb
  # Linha: após método valid?

  # Retorna true/false sem levantar exceção
  # @return [Boolean]
  def valido?
    valid?
    true
  rescue Brcobranca::BoletoInvalido
    false
  end
  ```

- [ ] **2.2** Criar método `to_hash_seguro`
  ```ruby
  # Arquivo: lib/brcobranca/boleto/base.rb

  # Retorna hash mesmo se inválido, com campo :valid e :errors
  # @return [Hash]
  def to_hash_seguro
    if valid?
      to_hash.merge(valid: true, errors: [])
    else
      dados_entrada.merge(
        valid: false,
        errors: errors.full_messages
      )
    end
  rescue Brcobranca::BoletoInvalido => e
    dados_entrada.merge(
      valid: false,
      errors: errors.full_messages
    )
  end
  ```

- [ ] **2.3** Melhorar mensagens de erro
  ```ruby
  # Arquivo: lib/brcobranca/util/errors.rb

  # Adicionar método para retornar erros como Hash
  def to_hash
    messages.transform_values(&:first)
  end

  def as_json
    to_hash.transform_keys(&:to_s)
  end
  ```

---

### Fase 3: Remessa API (🔄 A FAZER)

- [ ] **3.1** Implementar `Remessa::Base#to_hash`
  ```ruby
  # Arquivo: lib/brcobranca/remessa/base.rb

  def to_hash
    {
      tipo: self.class.to_s.split('::').last,
      formato: formato_remessa,
      empresa: dados_empresa,
      pagamentos: pagamentos.map(&:to_hash),
      arquivo: {
        nome_sugerido: nome_arquivo,
        conteudo_base64: Base64.strict_encode64(gera_arquivo)
      }
    }
  end

  def as_json
    to_hash.deep_transform_keys(&:to_s)
  end
  ```

- [ ] **3.2** Implementar `Remessa::Pagamento#to_hash`
  ```ruby
  # Arquivo: lib/brcobranca/remessa/pagamento.rb

  def to_hash
    {
      nosso_numero: nosso_numero,
      valor: valor,
      data_vencimento: data_vencimento,
      documento: documento,
      # ... todos os campos
    }
  end
  ```

- [ ] **3.3** Criar factory method `Remessa.criar`
  ```ruby
  # Arquivo: lib/brcobranca/remessa.rb

  def self.criar(banco:, formato:, **params)
    klass = case formato.to_s
            when '240' then Cnab240
            when '400' then Cnab400
            when '444' then Cnab444
            end

    banco_klass = klass.const_get(banco.to_s.camelize)
    banco_klass.new(params)
  end
  ```

---

### Fase 4: Retorno API (🔄 A FAZER)

- [ ] **4.1** Melhorar `Retorno::Base#to_hash`
  ```ruby
  # Arquivo: lib/brcobranca/retorno/base.rb

  def to_hash
    {
      codigo_registro: codigo_registro,
      agencia: agencia_com_dv,
      conta: cedente_com_dv,
      nosso_numero: nosso_numero,
      valor_titulo: valor_titulo,
      data_vencimento: data_vencimento,
      data_credito: data_credito,
      valor_recebido: valor_recebido,
      codigo_ocorrencia: codigo_ocorrencia,
      motivo_ocorrencia: motivo_ocorrencia,
      # ... todos os campos relevantes
    }.compact
  end
  ```

- [ ] **4.2** Criar factory method `Retorno.parse`
  ```ruby
  # Arquivo: lib/brcobranca/retorno.rb

  def self.parse(arquivo, banco: nil, formato: nil)
    # Auto-detectar formato se não informado
    formato ||= detectar_formato(arquivo)

    klass = case formato
            when :cnab240 then RetornoCnab240
            when :cnab400 then RetornoCnab400
            end

    registros = klass.load_lines(arquivo, banco: banco)
    {
      formato: formato,
      banco: banco,
      total_registros: registros.size,
      registros: registros.map(&:to_hash)
    }
  end
  ```

- [ ] **4.3** Implementar detecção automática de formato
  ```ruby
  # Arquivo: lib/brcobranca/retorno.rb

  def self.detectar_formato(arquivo)
    primeira_linha = arquivo.lines.first
    case primeira_linha&.size
    when 240 then :cnab240
    when 400 then :cnab400
    else
      raise ArgumentError, "Formato não reconhecido"
    end
  end
  ```

---

### Fase 5: Testes (🔄 A FAZER)

- [ ] **5.1** Testes para `valido?` e `to_hash_seguro`
  ```ruby
  # Arquivo: spec/brcobranca/boleto/base_api_spec.rb

  describe '#valido?' do
    it 'retorna true para boleto válido' do
      expect(boleto.valido?).to be true
    end

    it 'retorna false para boleto inválido sem exceção' do
      boleto_invalido = described_class.new
      expect(boleto_invalido.valido?).to be false
    end
  end

  describe '#to_hash_seguro' do
    it 'retorna hash com valid: true para boleto válido' do
      resultado = boleto.to_hash_seguro
      expect(resultado[:valid]).to be true
      expect(resultado[:errors]).to be_empty
    end

    it 'retorna hash com valid: false e errors para boleto inválido' do
      boleto_invalido = described_class.new
      resultado = boleto_invalido.to_hash_seguro
      expect(resultado[:valid]).to be false
      expect(resultado[:errors]).not_to be_empty
    end
  end
  ```

- [ ] **5.2** Testes para Remessa#to_hash
  ```ruby
  # Arquivo: spec/brcobranca/remessa/base_api_spec.rb
  ```

- [ ] **5.3** Testes para Retorno#to_hash
  ```ruby
  # Arquivo: spec/brcobranca/retorno/base_api_spec.rb
  ```

---

### Fase 6: Documentação (🔄 A FAZER)

- [ ] **6.1** Documentar API em `docs/api_referencia.md`
- [ ] **6.2** Criar exemplos de integração REST
- [ ] **6.3** Documentar migração do boleto_cnab_api

---

## TODO boleto_cnab_api

### Fase 1: Atualizar Dependências (🔄 A FAZER)

- [ ] **1.1** Atualizar brcobranca no Gemfile
  ```ruby
  # Arquivo: Gemfile

  # Antes:
  gem 'brcobranca', github: 'maxwbh/brcobranca'

  # Depois:
  gem 'brcobranca', '~> 12.2'
  # ou
  gem 'brcobranca', github: 'maxwbh/brcobranca', branch: 'master'
  ```

- [ ] **1.2** Remover pin do rghost
  ```ruby
  # Arquivo: Gemfile

  # Remover linha:
  gem 'rghost', '0.9.8'

  # brcobranca já gerencia a dependência
  ```

- [ ] **1.3** Rodar bundle update
  ```bash
  bundle update brcobranca
  bundle install
  ```

---

### Fase 2: Refatorar Endpoints de Boleto (🔄 A FAZER)

- [ ] **2.1** Refatorar GET /api/boleto/validate
  ```ruby
  # Arquivo: lib/boleto_api.rb

  # Antes:
  get :validate do
    boleto = BoletoApi.get_boleto(params[:bank], params)
    if boleto.valid?
      { valid: true }
    else
      { valid: false, errors: boleto.errors.full_messages }
    end
  end

  # Depois:
  get :validate do
    boleto = BoletoApi.get_boleto(params[:bank], params)
    {
      valid: boleto.valid?,
      errors: boleto.valid? ? [] : boleto.errors.full_messages
    }
  end
  ```

- [ ] **2.2** Refatorar GET /api/boleto/data
  ```ruby
  # Arquivo: lib/boleto_api.rb

  # Antes (código duplicado):
  get :data do
    boleto = BoletoApi.get_boleto(params[:bank], params)
    {
      codigo_barras: boleto.codigo_barras,
      linha_digitavel: boleto.linha_digitavel,
      nosso_numero: boleto.nosso_numero_boleto,
      agencia_conta: boleto.agencia_conta_boleto,
      # ... mais 10 campos mapeados manualmente
    }
  end

  # Depois (usando nova API):
  get :data do
    boleto = BoletoApi.get_boleto(params[:bank], params)
    boleto.as_json(somente_calculados: true)
  end
  ```

- [ ] **2.3** Refatorar GET /api/boleto/nosso_numero
  ```ruby
  # Arquivo: lib/boleto_api.rb

  # Antes:
  get :nosso_numero do
    boleto = BoletoApi.get_boleto(params[:bank], params)
    {
      nosso_numero: boleto.nosso_numero_boleto,
      nosso_numero_dv: boleto.nosso_numero_dv
    }
  end

  # Depois:
  get :nosso_numero do
    boleto = BoletoApi.get_boleto(params[:bank], params)
    dados = boleto.dados_calculados
    {
      nosso_numero: dados[:nosso_numero],
      nosso_numero_boleto: dados[:nosso_numero_boleto],
      nosso_numero_dv: dados[:nosso_numero_dv]
    }
  end
  ```

- [ ] **2.4** Adicionar novo endpoint GET /api/boleto/hash
  ```ruby
  # Arquivo: lib/boleto_api.rb

  desc 'Retorna todos os dados do boleto como JSON'
  params do
    requires :bank, type: String, desc: 'Código do banco'
    # ... outros parâmetros
  end
  get :hash do
    boleto = BoletoApi.get_boleto(params[:bank], params)
    boleto.as_json
  end
  ```

---

### Fase 3: Refatorar Endpoint de Retorno (🔄 A FAZER)

- [ ] **3.1** Remover RETORNO_FIELDS array
  ```ruby
  # Arquivo: lib/boleto_api.rb

  # Remover constante RETORNO_FIELDS (quando brcobranca tiver to_hash)
  ```

- [ ] **3.2** Refatorar POST /api/retorno
  ```ruby
  # Arquivo: lib/boleto_api.rb

  # Antes:
  post :retorno do
    pagamentos = Brcobranca::Retorno::Cnab400::Bradesco.load_lines(arquivo)
    pagamentos.map do |p|
      RETORNO_FIELDS.map { |f| [f, p.send(f)] }.to_h
    end
  end

  # Depois (quando brcobranca tiver Retorno.parse):
  post :retorno do
    resultado = Brcobranca::Retorno.parse(
      arquivo,
      banco: params[:bank],
      formato: params[:formato]
    )
    resultado.as_json
  end
  ```

---

### Fase 4: Melhorias de API (🔄 A FAZER)

- [ ] **4.1** Padronizar respostas de erro
  ```ruby
  # Arquivo: lib/boleto_api.rb

  rescue_from Brcobranca::BoletoInvalido do |e|
    error!({
      error: 'BoletoInvalido',
      message: e.message,
      errors: e.errors&.full_messages || []
    }, 422)
  end

  rescue_from Brcobranca::RemessaInvalida do |e|
    error!({
      error: 'RemessaInvalida',
      message: e.message
    }, 422)
  end
  ```

- [ ] **4.2** Adicionar suporte a PIX
  ```ruby
  # Arquivo: lib/boleto_api.rb

  # No método get_boleto, aceitar parâmetro emv:
  def self.get_boleto(bank, values)
    # ... código existente ...

    # Adicionar suporte a EMV/PIX
    if values[:emv]
      campos[:emv] = values[:emv]
    end

    Brcobranca::Boleto.const_get(bank.camelize).new(campos)
  end
  ```

- [ ] **4.3** Documentar novos endpoints no README
  ```markdown
  ### Novos Endpoints (v2.0)

  - `GET /api/boleto/hash` - Retorna todos os dados do boleto
  - Parâmetro `emv` para suporte a PIX
  ```

---

### Fase 5: Testes (🔄 A FAZER)

- [ ] **5.1** Atualizar testes para usar nova API
- [ ] **5.2** Adicionar testes para endpoint /hash
- [ ] **5.3** Adicionar testes para suporte PIX
- [ ] **5.4** Testar compatibilidade com brcobranca 12.2.0

---

### Fase 6: Deploy (🔄 A FAZER)

- [ ] **6.1** Atualizar Dockerfile
- [ ] **6.2** Testar em ambiente de staging
- [ ] **6.3** Atualizar documentação de deploy
- [ ] **6.4** Release v2.0.0

---

## Cronograma Sugerido

```
Semana 1-2: Fase 2 brcobranca (validação melhorada)
Semana 3-4: Fase 3 brcobranca (Remessa API)
Semana 5-6: Fase 4 brcobranca (Retorno API)
Semana 7:   Fase 5-6 brcobranca (testes e docs)
Semana 8:   Release brcobranca v12.3.0

Semana 9:   Fase 1-2 boleto_cnab_api (atualizar deps, refatorar boleto)
Semana 10:  Fase 3-4 boleto_cnab_api (refatorar retorno, melhorias)
Semana 11:  Fase 5-6 boleto_cnab_api (testes e deploy)
Semana 12:  Release boleto_cnab_api v2.0.0
```

---

## Guia de Migração

### Para usuários do boleto_cnab_api

1. **Atualizar para v2.0.0**
   ```bash
   docker pull maxwbh/boleto_cnab_api:2.0.0
   ```

2. **Novos endpoints disponíveis**
   - `GET /api/boleto/hash` - Todos os dados do boleto

3. **Breaking changes**
   - Nenhum (compatível com v1.x)

### Para desenvolvedores integrando diretamente com brcobranca

1. **Atualizar gem**
   ```ruby
   gem 'brcobranca', '~> 12.2'
   ```

2. **Usar nova API**
   ```ruby
   # Antes
   boleto = Brcobranca::Boleto::Sicoob.new(params)
   dados = {
     codigo_barras: boleto.codigo_barras,
     linha_digitavel: boleto.linha_digitavel,
     # ... mapear cada campo
   }

   # Depois
   boleto = Brcobranca::Boleto::Sicoob.new(params)
   dados = boleto.to_hash(somente_calculados: true)
   ```

3. **Validação sem exceção (v12.3.0+)**
   ```ruby
   # Antes
   begin
     boleto.codigo_barras
   rescue Brcobranca::BoletoInvalido => e
     # tratar erro
   end

   # Depois
   resultado = boleto.to_hash_seguro
   if resultado[:valid]
     # usar dados
   else
     # resultado[:errors] contém os erros
   end
   ```

---

## Referências

- [brcobranca GitHub](https://github.com/Maxwbh/brcobranca)
- [boleto_cnab_api GitHub](https://github.com/Maxwbh/boleto_cnab_api)
- [CHANGELOG brcobranca](../CHANGELOG.md)
- [API Reference](./api_referencia.md)

---

> **Nota:** Este documento deve ser atualizado conforme as tarefas forem concluídas.
> Marque os items com [x] quando finalizados.

# Política de Segurança

## Versões Suportadas

Nós fornecemos atualizações de segurança para as seguintes versões do BRCobranca:

| Versão | Suportada          |
| ------ | ------------------ |
| 12.x   | :white_check_mark: |
| 11.x   | :white_check_mark: |
| 10.x   | :x:                |
| < 10.0 | :x:                |

## Reportando uma Vulnerabilidade

A segurança do BRCobranca é levada a sério. Se você descobriu uma vulnerabilidade de segurança, agradecemos sua ajuda em divulgá-la de forma responsável.

### Como Reportar

**NÃO** crie uma issue pública para vulnerabilidades de segurança.

Em vez disso, envie um e-mail para: **kivanio@gmail.com**

Inclua as seguintes informações:

1. **Descrição da vulnerabilidade**
   - Tipo de problema (ex: SQL injection, XSS, CSRF, etc.)
   - Localização do código afetado (arquivo e linha, se possível)

2. **Impacto**
   - Qual é o impacto potencial da vulnerabilidade?
   - Quem é afetado?

3. **Passos para Reproduzir**
   - Passo a passo detalhado para reproduzir a vulnerabilidade
   - Proof of Concept (PoC) se disponível

4. **Informações do Ambiente**
   - Versão do BRCobranca
   - Versão do Ruby
   - Sistema operacional

5. **Possível Solução** (opcional)
   - Se você tiver sugestões de como corrigir

### O Que Esperar

1. **Confirmação de Recebimento**: Você receberá uma confirmação em até 48 horas
2. **Avaliação Inicial**: Avaliaremos a vulnerabilidade em até 7 dias
3. **Plano de Ação**: Se confirmada, trabalharemos em uma correção
4. **Divulgação Coordenada**: Trabalharemos com você para divulgar a vulnerabilidade de forma responsável

### Processo de Divulgação

1. **Relatório Inicial**: Você reporta a vulnerabilidade privadamente
2. **Validação**: Confirmamos e validamos o problema
3. **Desenvolvimento da Correção**: Desenvolvemos e testamos a correção
4. **Notificação Prévia**: Notificamos usuários críticos antes do lançamento público
5. **Lançamento da Correção**: Publicamos a correção em uma nova versão
6. **Divulgação Pública**: Após o lançamento, divulgamos detalhes da vulnerabilidade

### Política de Divulgação Responsável

Solicitamos que você:

- Nos dê tempo razoável para corrigir a vulnerabilidade antes de divulgá-la publicamente
- Não explore a vulnerabilidade além do necessário para demonstrá-la
- Não acesse, modifique ou delete dados de terceiros
- Mantenha a confidencialidade sobre a vulnerabilidade até que seja corrigida

## Áreas de Interesse para Segurança

Ao auditar o BRCobranca, preste atenção especial a:

### 1. Geração de PDFs
- Injeção de código PostScript/GhostScript
- Path traversal em templates
- Validação de entrada para dados do boleto

### 2. Processamento de Arquivos CNAB
- Validação de formato de arquivo
- Parsing seguro de dados bancários
- Prevenção de buffer overflow em strings

### 3. Validações de Dados
- Validação de números de documentos (CPF/CNPJ)
- Sanitização de valores monetários
- Validação de códigos de barras

### 4. Dependências
- Vulnerabilidades em gems dependentes
- Versões desatualizadas de bibliotecas

## Boas Práticas de Segurança para Usuários

### Validação de Entrada

```ruby
# SEMPRE valide dados de entrada do usuário
boleto.cedente = params[:cedente].to_s.strip[0..100]
boleto.valor = params[:valor].to_f.abs
```

### Proteção de Dados Sensíveis

```ruby
# NÃO exponha dados sensíveis em logs
Rails.logger.info "Boleto gerado para: [REDACTED]"

# Use variáveis de ambiente para configurações sensíveis
ENV['BANCO_AGENCIA']
ENV['BANCO_CONTA']
```

### Geração Segura de PDFs

```ruby
# Valide todos os dados antes de gerar o PDF
if boleto.valid?
  pdf = boleto.to(:pdf)
else
  handle_validation_errors(boleto.errors)
end
```

### Arquivos CNAB

```ruby
# Valide o formato antes de processar
begin
  arquivo = Brcobranca::Remessa::Cnab400::Base.new(dados)
  if arquivo.valid?
    arquivo.gera_arquivo
  end
rescue Brcobranca::RemessaInvalida => e
  logger.error "Arquivo CNAB inválido: #{e.message}"
end
```

## Dependências de Segurança

### Atualizações Automáticas

O projeto usa:
- **Dependabot** para atualizações automáticas de dependências
- **GitHub Security Advisories** para alertas de segurança

### Auditoria de Dependências

Execute regularmente:

```bash
# Verificar vulnerabilidades conhecidas
bundle audit check --update

# Atualizar dependências
bundle update --conservative
```

## Política de Patches de Segurança

### Severidade Crítica
- Correção em até 24 horas
- Lançamento de patch imediato
- Notificação de usuários

### Severidade Alta
- Correção em até 7 dias
- Lançamento de patch prioritário
- Notificação via CHANGELOG

### Severidade Média/Baixa
- Correção na próxima versão regular
- Documentação no CHANGELOG

## Recursos Adicionais

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Ruby Security Guide](https://guides.rubyonrails.org/security.html)
- [Brakeman Scanner](https://brakemanscanner.org/) - Para aplicações Rails

## Reconhecimento

Agradecemos aos pesquisadores de segurança que reportam vulnerabilidades responsavelmente. Reconheceremos sua contribuição (se desejado) quando a correção for publicada.

### Hall of Fame

Nenhum relato de vulnerabilidade ainda. Seja o primeiro a nos ajudar!

## Contato

Para questões de segurança: **kivanio@gmail.com**

Para questões gerais: [GitHub Issues](https://github.com/kivanio/brcobranca/issues)

---

**Última atualização**: 2025-11-27

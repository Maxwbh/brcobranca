---
name: Suporte a Novo Banco
about: Solicitar suporte a um novo banco ou carteira
title: '[BANCO] '
labels: enhancement, new-bank
assignees: ''
---

## Informações do Banco

- **Nome do Banco:**
- **Código FEBRABAN:**
- **Site Oficial:**

## Tipo de Solicitação

- [ ] Novo banco (ainda não suportado)
- [ ] Nova carteira (banco já existe)
- [ ] Suporte a CNAB240 (banco existe apenas com CNAB400)
- [ ] Suporte a CNAB400 (banco existe apenas com CNAB240)
- [ ] Outro: ___________

## Documentação Disponível

<!-- Cole aqui links para a documentação oficial do banco -->

- **Layout de Boleto:**
- **Especificação de Código de Barras:**
- **Layout CNAB (se aplicável):**
- **Manual de Cobrança:**

## Informações Técnicas

### Carteira(s) Desejada(s)

<!-- Liste as carteiras que você precisa -->

-

### Campos Específicos

<!-- O banco possui campos específicos ou validações especiais? Descreva aqui -->

### Cálculos Especiais

<!-- O banco usa cálculos diferentes para nosso número, DV, código de barras, etc.? -->

## Acesso para Testes

<!-- Você tem acesso para testar o banco? -->

- [ ] Tenho conta homologação/teste no banco
- [ ] Tenho conta produção e posso testar
- [ ] Não tenho acesso, apenas documentação
- [ ] Posso fornecer acesso para testes aos mantenedores

## Disponibilidade para Contribuir

<!-- Você pode contribuir com a implementação? -->

- [ ] Posso implementar e submeter PR
- [ ] Posso testar implementações
- [ ] Posso fornecer documentação
- [ ] Posso validar contra sistema real do banco
- [ ] Apenas solicitando, não posso contribuir no momento

## Casos de Uso

<!-- Descreva como você pretende usar -->

- **Volume estimado:** [boletos/mês]
- **Uso:** [ ] Produção [ ] Desenvolvimento [ ] Testes
- **Urgência:** [ ] Alta [ ] Média [ ] Baixa

## Exemplos

<!-- Se possível, forneça exemplos de boletos do banco (sem dados reais!) -->

### Linha Digitável de Exemplo

```
Exemplo de linha digitável (pode ser fictícia seguindo o padrão do banco)
```

### Código de Barras de Exemplo

```
Código de barras correspondente
```

## Diferenças Conhecidas

<!-- O banco tem alguma peculiaridade em relação aos padrões FEBRABAN? -->

## Arquivos para Anexar

<!-- Se tiver PDFs do banco, layouts, etc., anexe aqui -->
<!-- ATENÇÃO: Remova qualquer dado sensível antes de anexar! -->

## Referências Adicionais

<!-- Links úteis, fóruns, discussões sobre este banco -->

## Informações Adicionais

<!-- Qualquer outra informação que possa ajudar -->

---

**Nota para Contribuidores:**

Se você deseja implementar suporte a este banco, por favor:

1. Consulte o [Guia de Contribuição](../../CONTRIBUTING.md)
2. Veja a seção "Adicionando Suporte a um Novo Banco"
3. Use bancos similares como referência (ex: outros bancos estaduais)
4. Garanta que tem documentação oficial do banco
5. Implemente testes completos

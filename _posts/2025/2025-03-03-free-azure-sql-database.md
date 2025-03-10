---
title: "Azure SQL Database Gratuito em produção????"
date: 2025-03-09 01:33:00
categories: [Azure]
tags: [azure, sql]
slug: 'free-azure-sql-database'
image:
  path: assets/img/33/33-header.webp
---

Olá pessoal! Blz?

Recentemente a Microsoft passou para GA (General Available) o Azure SQL Database gratuito, estava em preview desde ano passado, e até ai eu achava até normal ainda na versão preview, porque no meu entendimento isso seria uma boa oportunidade para testar o produto de forma gratuita, ou até mesmo empresas usarem esse recurso em ambientes de desenvolvimentos/testes.

Mas ai eu recebi algumas perguntas no sentido: ***"Agora que o recurso está em GA eu posso usá-lo em produção??"***, claro que minha resposta foi **"NÃO"**. Mas antes de explicar o porque dessa resposta e onde/quando podemos usar essa recurso vamos entende-lo melhor.

## O que é o Azure SQL Database gratuito?

O Azure SQL Database é um serviço (PaaS) poderoso para banco de dados e agora possui uma versão gratuita, cada assinatura do Azure permite que você crie até 10 bancos de dados, para cada banco de dados, você recebe uma **concessão mensal de 100.000 segundos de computação**, **32 GB de armazenamento de dados** e **32 GB de armazenamento de backup** gratuitamente e o valor gratuito é renovado para cada banco de dados no início do próximo mês.

Mas como citado acima é gratuito mas tem um limite, ou seja, o que acontece quando atingir esse limite??? Quando você cria o recurso temos 2 (duas) opções de configuração para quando atingirmos o limite mensal da atividade de vCore ou armazenamento:

- **Cada banco de dados poderá ser pausado automaticamente até o início do próximo mês.**

- **Manter o banco de dados disponível, com uso de vCore e quantidade de armazenamento acima dos limites gratuitos cobrados no método de cobrança da assinatura.**

## Como criar o recurso Azure SQL Database gratuito

Para criar o recurso na forma gratuita não é muito diferente de como criar naturalmente, só temos que nos atentar a clicar no botão para requisitar a oferta conforme imagem abaixo:

![free-azure-sql-database](/assets/img/33/01.png){: .shadow .rounded-10}

Com isso a oferta é ativada e só temos que escolher o que acontecerá quando o recurso atingir o limite de utilização, como explicamos acima temos 2 (duas) opções:

- **Pausa automática**

- **Continuar usando com custos adicionais**

![free-azure-sql-database](/assets/img/33/02.png){: .shadow .rounded-10}

Os demais passos são os mesmo que você tem na versão paga, mas vale se atentar se no ***"Review"*** de criação do recurso se temos o custo **"0.00"** para o recurso que será criado:

![free-azure-sql-database](/assets/img/33/03.png){: .shadow .rounded-10}

## Usar ou não em produção?

O argumento que me fizeram para a pergunta sobre usar ou não esse recurso na camada gratuita para ambientes de produção foi: ***"Então mesmo que atinja o limite pode deixar o banco de dados funcional e começar a pagar a partir dali".***

Eu não posso negar que para um banco de dados para um serviço pequeno é muito útil, mas mesmo um serviço pequeno ao usar o Azure SQL Database na versão gratuita temos algumas limitações muito importantes de serem consideradas:

- **NÃO TEM UM SLA** (contrato de nível de serviço) então se o serviço ficar indisponível não adianta cobrar a Microsoft.

- **Elastic Jobs e DNS Alias não estão disponíveis.**

- **A oferta gratuita do Azure SQL Database não pode fazer parte de um pool elástico ou de um grupo de failover.**

> Só pelo fato de não ter o SLA não é possível que ainda queirão usar em propdução 😁😁😁😁.
{: .prompt-tip }

Então na minha opinião a resposta para a pergunta desse artigo é ***"Não, eu não recomendo o uso em ambiente de produção, é um excelente recurso para se usar em ambiente de desenvolvimento e testes"***.

## Concluindo!

Eu quis trazer algumas perguntas que recebo no dia a dia e essa eu achei bem interessante escrever sobre, o Azure SQL Database é um excelente e maduro recurso do Microsoft Azure e ajudará muito na versão gratuita para testarmos o recurso, usar em estudos e laboratórios sem o medo do custo que um banco de dados pode trazer, no mais é nesse tipo de ambiente que podemos explorar esse recurso.

Bom pessoal, eu tenho usado isso em alguns ambientes e acredito que possa ser bem útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/pt-br/azure/azure-sql/database/sql-database-paas-overview?view=azuresql" target="_blank">O que é o Azure SQL Database</a>

<a href="https://learn.microsoft.com/pt-br/azure/azure-sql/database/free-offer-faq?view=azuresql#o-banco-de-dados-sql-do-azure-oferece-gratuitamente-um-banco-de-dados-de-qualidade-de-produ--o" target="_blank">Perguntas frequentes sobre a oferta gratuita do Banco de Dados SQL do Azure</a>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!

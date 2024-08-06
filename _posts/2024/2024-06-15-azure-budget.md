---
#layout: post
title: 'Cost Management - Budgets: como controlar os gastos da sua Assinatura Azure'
date: 2024-06-15 01:33:00
slug: 'azure-budget'
categories:  ['Azure', 'Finops']
tags: ['Azure', 'Cost', 'Budget', 'Finops']
image:
  path: assets/img/14/14-header.webp
---

Olá pessoal! Blz?

Gostaria de trazer a vocês uma dica para controlar/alertar os gastos no Microsoft Azure, com a facilidade de podermos criar recursos sempre que precisamos a Cloud nos traz facilidade mas também nos tras a preocupação com os gastos. Quem nunca criou uma máquina virtual ou outro recurso e esqueceu de apagar ou desligar após testa-lo? 

Uma das atividades de um Cloud Engineer, além de manter o ambiente ok, é manter o custo dentro do esperado pela empresa e se for uma conta pessoal evitar surpresas na cobrança do cartão de crédito.

Quando estamos estudando e usamos uma conta trial, se esquecermos ou gastarmos demais os creditos irão simplesmente acabar, mas quando usamos uma conta **Pay as you go (PAYG)** que pagamos pelo o que consumimos, esquecer algo ligado ou esquecer de apagar algo que não mais utilizamos pode deixar essa conta bem cara.

Com o **Azure Cost Management** temos uma ferramenta que nos ajuda a controlar/alertar os gastos em nosso ambiente, essa ferramenta é o **Budget (Orçamento)**.

## O que é o Budget (Orçamento) e como funciona

Você pode configurar alertas com base em seu custo real ou previsto para garantir que seu gasto esteja dentro do limite de gastos estipulados por você ou sua empresa, você pode criar vários orçamentos para diferentes períodos (mensal, trimestral ou anual) e diferentes escopos (Grupo de Recursos, Assinatura ou Grupo de Gerenciamento). Por exemplo, você pode ter um orçamento para sua assinatura inteira e um especifico para um Grupo de Recurso, e na sua empresa se os ambiente de Desenvolvimento e Produção estão na mesma assinatura, você pode definir um orçamento para cada ambiente.

As notificações são acionadas quando os limites orçamentários são excedidos ou atingem a  porcentagem que você definir, os recursos não são afetados e seu consumo não é interrompido. 

Os orçamentos são redefinidos automaticamente ao final do período que você escolheu, quando a data de expiração é atingida o orçamento é excluido.

## Como criar um Budget / Orçamento

Para criar um orçamento, você precisa selecionar qual o escopo você irá usar, e no menu a esquerda terá a opção **"Cost Management"** e depois de expandir e escolher a opção **"Budgets"**, nesse exemplo eu irei usar como escopo minha assinatura para que eu tenha um controle melhor dos gastos.

![azure-budget](/assets/img/14/01.png)

Podemos ver na imagem abaixo que abrindo o **Cost Management - Budgets** a partir da assinatura ele assume que o escopo do orçamento será a **Assinatura: Luiz Henrique - Labs**

![azure-budget](/assets/img/14/02.png)

Para adicionar um orçamento, clique no botão **"+ Add"**, você verá uma tela com um gráfico com os seus gastos nos meses passados e a esquerda as opções para criar um novo orçamento. 

É exibido o seu gasto no mês passado e pode comparar com o meses anteriores, esse gráfico te ajuda a estipular um valor de orçamento que irá configurar. 

![azure-budget](/assets/img/14/03.png)

A criação do orçamento é feita em 2 etapas, a primeira criamos o orçamento e a segunda o alerta. Para criar um orçamento temos 5 campos que precisamos preencher:

- Name: nome único para o orçamento
- Reset period: define qual o período do orçamento que ele fazer a redefinição dos custos para o alerta


![azure-budget](/assets/img/14/04.png)

- Creation date: dependendo do que você escolher acima ele irá definir qual será o primeiro dia do orçamento
- Expiration date: data que o orçamento nao terá mais validade e não irá mais alertar os gastos
- Amount: qual o valor no periodo selecionado acima você quer estipular.

> O Azure irá sugerir um orçamento baseado nas previsões de gastos com os recursos que você tem atualmente, baseado nisso, na imagem abaixo o Azure esta sugerindo que meu orçamento seja de R$ 725,00.
{: .prompt-tip }

![azure-budget](/assets/img/14/05.png)

Na segunda etapa iremos criar o alerta para o orçamento que criamos na aba anterior, para isso devemos preencher os seguintes campos:

- Alert conditions:
  - Tipo: o alerta será baseado no gasto atual ou na previsão de gastos 
  - % of budget: porcentagem do orçamento que ao ser atingido será alertado
  - Amount: definido automaticamente de acordo com o valor do orçamento e a porcentagem escolhida no campo anterior
  - Action group: se tiver um action group configurado pode ser usado
  <br><br>
- Alert recipients (email): para quais e-mails serão enviados os alertas

- Language preferente: qual o idioma você prefere receber o e-mail de alerta

![azure-budget](/assets/img/14/06.png)

Após os campos preenchidos clicamos no botão **"Create"**.

## Recebendo o alerta

Quando o valor configurado é atingido você receberá um e-mail como o exemplo abaixo, nesse e-mail você tem o **valor do orçamento (Budget threshold)**, o **valor do gasto atual (Evaluated value)** e o **valor que fez disparar o e-mail Notification threshold for alert)**, no exemplo eu configurei para disparar um e-mail quando atingíssemos o valor de 10%, fiz isso somente para disparar o e-mail mais rapidamente, mas normalmente eu configuro quando se atinge 50% e a previsão de gastos esteja projetada para 75% no mês.

![azure-budget](/assets/img/14/07.png)

## Concluindo!

Criar orçamentos no Azure é mais uma ferramenta para ter um controle mais detalhado dos gastos que você tem na Cloud, um gasto descontrolado pode ter várias surpresas inesperadas, como uma fatura de cartão de crédito muito alta. Com o recebimento do alerta do orçamento você pode ir até o portal do Azure e ver quais recursos você não precisa naquele momento e/ou restruturar seu ambiente para que o custo fique dentro do orçado.

Configurando os orçamentos de forma coerente você pode alinhar seus custos de cloud com seus objetivos de negócios e evitar cobranças inesperadas.

Bom pessoal, espero que tenha gostado e que esse artigo seja útil a vocês!

## Artigos relacionados

<a href="https://docs.microsoft.com/pt-br/azure/cost-management-billing/costs/tutorial-acm-create-budgets" target="_blank">Crie e gerencie orçamentos</a> 

<a href="https://blog.arantes.net.br/posts/azure-finops-orphaned-resources/" target="_blank">Azure FinOps: como diminuir custos removendo recursos órfãos</a> 

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
<hr>
---
title: "Reserved Instance vs Saving Plan no Azure (e onde entra o Azure Hybrid Benefit)"
date: 2025-12-02 01:00:00
categories: [Azure, Finops]
tags: [azure, finops]
slug: 'azure-reserved-instances-saving-plans'
image:
  path: /assets/img/48/48-header.webp
---

Olá pessoal! Blz?

No artigo de hoje gostaria de trazer um assunto muito importante nos dias de hoje e deve ser rotina de qualquer profissional que trabalhe com Cloud que é a parte de custo e/ou **como economizar no Microsoft Azure.**

Eu trabalhei em alguns projetos de migração para Cloud e também em projetos saindo da Cloud de volta a ambientes On premises, tudo isso devido ao alto custo do ambiente Cloud que se tornou ao não tomar certos cuidados e/ou um bom planejamento.

Quando trabalhamos em ambientes on-premises o limitador sempre é o hardware, eu mesmo já tive que justificar, rejustificar, ter o pedido negado até depois de muito tempo convencer gestores a investir em novo hardware o que sempre é um gasto muito alto. Com isso sempre "aprendemos" a trabalhar no gargalo.

A ida para a cloud nos tira esse limitador de hardware, a tão sonhada quantidade de memória RAM está ali disponível ao alcance de um clique, mas esse clique pode sair caro no final do mês.

Então o que quero dizer é que uma ida bem sucedida para a Cloud depende de um bom planejamento inical e um controle eficaz durante o período de operação dos ambientes. Uma das maneiras mais eficientes de reduzir custos no Azure é utilizar **modelos de pricing com compromisso de uso**, como **Reserved Instances e Savings Plans.**

Muitas organizações acabam pagando mais do que deveriam simplesmente por não utilizar esses recursos de otimização de custos. E vamos ver abaixos algumas formas de cobrança e como economizar no Microsoft Azure.

## O problema do modelo Pay-as-you-go (PAYG)

Por padrão, a maioria dos recursos no Azure é cobrada no modelo Pay-as-you-go, ou seja: **você paga somente pelo consome**, **sem compromisso de uso** e **sem desconto significativo**.

Esse modelo oferece flexibilidade, então com uma conta no Microsodft Azure você começar a criar recursos que precisa, seja de maneira controlada ou frenética, mas lembre-se para criar uma conta nesse formato você precisou inserir o número do cartão de crédito ao criar a assinatura e será nesse cartão que o custo será debitado no final do mês.

O modelo PAYG é realmente muito flexível, mas não é o mais econômico para workloads previsíveis, se você tem uma arquitetura ou sabe qual será o ambiente que irá manter na cloud você poderia se organizar e tentar alguma maneira de economizar tendo um **compromisso de uso** com a Microsoft e o Azure oferece modelos com compromisso de uso em troca de desconto.

## O que são Azure Reserved Instances

Reserved Instances (RI) são reservas de capacidade para recursos específicos do Azure por um período determinado.

Ao reservar recursos antecipadamente, a Microsoft oferece descontos significativos, que podem chegar a **72% em comparação com Pay-as-you-go.** Você pode pagar por uma reserva de forma antecipada ou mensal. O custo total das reservas antecipadas e mensais é o mesmo e você não paga nenhuma taxa adicional quando opta por pagar mensalmente. 

Não são todos os recursos que aceitam reserva, mas a lista hoje já é grande e você pode consultar nesse link: <a href="https://learn.microsoft.com/pt-br/azure/cost-management-billing/reservations/save-compute-costs-reservations#charges-covered-by-reservation" target="_blank">Preços cobertos pela reserva</a> 

Mas basicamente no dia de hoje é possível reservar os recursos abaixo:

![azure-reserved-instances-saving-plans](/assets/img/48/01.png){: .shadow .rounded-10}

<b>

Vamos dar um exemplo simples de como funciona uma reserva de máquina virtual:

- **Você reserva:**

  - um tipo específico de recurso, por exemplo: máquinas virtuais com SKU **Standard D4s v5**

  - em uma região específica, por exemplo: **East Us 2**

  - por 1 ano ou 3 anos

Isso significa que você está comprometido a pagar por esse recurso durante o período escolhido, independentemente do uso e com essa **"garantia"** de que você irá permanecer/reservar esse recurso a Microsoft lhe concede um desconto considerável.

Abaixo usando a Calculadora de Preços do Azure temos uma comparação com **modelos PAYG**, **reserva de 1 ano** e **reserva de 3 anos:**

![azure-reserved-instances-saving-plans](/assets/img/48/02.png){: .shadow .rounded-10}

> No exemplo acima o desconto final foi de **67,83%** em relação do preço PAYG e reserva de 3 anos
{: .prompt-tip } 

## O que é Azure Savings Plan

O Azure Savings Plan é uma alternativa mais flexível às Reserved Instances. O plano de economia do Azure para computação permite que as organizações reduzam os custos qualificados de uso de computação em até 65% (em relação às tarifas padrão de pagamento conforme o uso) ao **assumir um compromisso financeiro por hora por 1 ou 3 anos**. Ao contrário das reservas do Azure, sendo direcionadas a cargas de trabalho estáveis e previsíveis, os planos de economia do Azure são direcionados para cargas de trabalho dinâmicas e/ou em evolução. 

Resumindo em poucas palavras: ***em vez de reservar um recurso específico, você se compromete com um valor de gasto por hora.***

Os planos de poupança do Azure estão disponíveis para organizações com contratos enterprise (EA), MCA (Contrato de Cliente da Microsoft) ou MPA (Contrato de Parceiro da Microsoft). 

Exemplo:

```text
$10 por hora durante 1 ano
```

Enquanto seu consumo atingir esse valor, você recebe descontos.

O Azure aplica automaticamente o desconto para os recursos elegíveis dentro do seu compromisso. Esses recursos incluem:

- **Virtual Machines**

- **App Service**

- **Container Instances**

- **Azure Functions**

A vantagem do Savings Plan é a flexibilidade, com esse tipo de plano você pode mudar: **tipo de VM**, **região**, **tamanho de instância**. Isso torna o Savings Plan ideal para ambientes com mudanças frequentes, mas o **desconto costuma ser menor que o das Reserved Instances.**

![azure-reserved-instances-saving-plans](/assets/img/48/03.png){: .shadow .rounded-10}

## Comparação direta entre Reserved Instances	e Savings Plan

Tanto **Reserved Instances** quanto **Savings Plan** são formas de reduzir custos no Azure com base em compromisso de uso, mas com abordagens diferentes.

As **Reserved Instances** oferecem o maior desconto, porém com menos flexibilidade. Você precisa definir previamente o tipo de recurso, região e período (1 ou 3 anos), sendo mais indicadas para workloads estáveis e previsíveis.

Já o **Savings Plan** traz mais flexibilidade. Em vez de reservar recursos específicos, você se compromete com um valor de gasto por hora, e o desconto é aplicado automaticamente em diferentes serviços. Isso o torna ideal para ambientes dinâmicos ou em constante mudança.

![azure-reserved-instances-saving-plans](/assets/img/48/05.png){: .shadow .rounded-10}

> No exemplo acima o desconto usando o preço PAYG e saving plan de 1 e de 3 anos
{: .prompt-tip } 

**De forma geral:**

- **Reserved Instances** → maior economia, menor flexibilidade

- **Savings Plan** → mais flexibilidade, economia um pouco menor

## Quando usar Reserved Instances

Reserved Instances são ideais para workloads previsíveis. Nesses casos, maximizar o desconto faz sentido:

- **banco de dados de produção**

- **servidores de aplicações estáveis**

- **workloads que raramente mudam de tamanho**

- **ambientes com arquitetura consolidada**

## Quando usar Savings Plan

Savings Plans funcionam melhor quando existe variabilidade de consumo, a flexibilidade compensa o desconto menor.

- **ambientes Dev/Test**

- **workloads escaláveis**

- **clusters Kubernetes**

- **ambientes que ainda estão evoluindo**

![azure-reserved-instances-saving-plans](/assets/img/48/04.png){: .shadow .rounded-10}

## O que é Azure Hybrid Benefit

O **Azure Hybrid Benefit** é outro recurso importante de otimização de custos. O Azure Hybrid Benefit permite reutilizar licenças existentes de Windows Server e SQL Server no Azure, reduzindo significativamente os custos.

Na prática, você deixa de pagar pela licença embutida no recurso e paga apenas pelo compute, aproveitando contratos já existentes (como **Software Assurance**).

Esse benefício pode ser combinado com **Reserved Instances ou Savings Plan**, aumentando ainda mais a economia — sendo especialmente útil em cenários de migração de workloads on-premises para o Azure.

**Abaixo um exemplo prático:**

`Uma VM Windows no Azure normalmente inclui: **custo da VM** e **custo da licença Windows**`

Com Azure Hybrid Benefit, você pode trazer sua licença on-premises e pagar apenas pelo compute.

Isso pode reduzir custos em até 40% adicionais.

### Combinando Hybrid Benefit com Reserved Instances

Aqui está uma estratégia comum usada por arquitetos de cloud em uma migração de DataCenters on-premises para cloud, por exemplo:

- **VM Windows**
- **Reserved Instance (3 anos)**
- **Azure Hybrid Benefit**

Isso pode reduzir custos de VMs Windows em até 80%.

## Concluindo!

**Reserved Instances**, **Savings Plan** e **Azure Hybrid Benefit** são recursos essenciais para reduzir custos no Azure. Cada um atende a um cenário específico e, na prática, combinar essas estratégias é o caminho mais eficiente para equilibrar custo, flexibilidade e governança em ambientes cloud.

A imagem abaixo define bem o artigo e os planos de consumo no Microsoft Azure:

![azure-reserved-instances-saving-plans](/assets/img/48/06.png){: .shadow .rounded-10}

## Artigos relacionados

<a href="https://learn.microsoft.com/pt-br/azure/cost-management-billing/savings-plan/savings-plan-compute-overview" target="_blank">O que são os planos de economia do Azure para computação?</a>

<a href="https://learn.microsoft.com/pt-br/windows-server/get-started/azure-hybrid-benefit?tabs=azure" target="_blank">Benefício Híbrido do Azure para Windows Server</a>

<a href="https://learn.microsoft.com/pt-pt/azure/cost-management-billing/manage/ea-portal-vm-reservations" target="_blank">Instâncias reservadas de VM do Azure EA</a>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
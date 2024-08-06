---
#layout: post
title: 'Azure Traffic Manager: um excelente balanceador de carga baseado em DNS'
date: 2024-06-02 10:33:00
slug: 'azure-traffic-manager'
categories: ['Azure']
tags: ['Azure', 'Load Balancer']
image:
  path: assets/img/13/13-header.webp
---

Olá pessoal! Blz?

Nesse artigo gostaria de demonstrar algo sobre **Azure Traffic Manager**, confesso que peguei poucas demandas para trabalhar com esse recurso mas que pode ser extremamente útil quando se precisa de um load balancer baseado em DNS. Mas a pergunta que geralmente fazemos é: ***Qual Load Balancer usar já que no Microsoft Azure temos 4 opções?***

Primeiramente temos que saber a diferenças entre eles para que possamos analisar qual se encaixa melhor para o que precisamos, os 4 Load Balancers no Azure são:

- **Application Gateway:** quando precisamos balancear a carga entre os servidores em uma região na camada de aplicativo (camada 7)
- **Load Balancer:** quando precisamos fazer o balanceamento de carga de camada de rede (camada 4)
- **Front Door:** otimizar o roteamento global do seu tráfego da Web e otimizar o desempenho e a confiabilidade do usuário final de nível superior por meio de um failover global rápido
- **Traffic Manager:** quando o balanceamento de carga é baseado em DNS (camada 7)

Entendendo como cada load balancer fica mais fácil decidir qual devemos usar, nesse artigo falaremos sobre o **Azure Traffic Manager.**

## O que é o Azure Traffic Manager?

O Azure Traffic Manager é um serviço baseado em DNS que distribui o tráfego entre várias regiões ou endpoints (ponto de extremidade). Ele funciona na camada de aplicação (camada 7) e pode rotear o tráfego com base em vários critérios, alguns critérios como **desempenho**, **prioridade**, **localização geográfica** ou **round-robin**. O Azure Traffic Manager também pode monitorizar a saúde dos seus pontos finais e fazer o failover automaticamente para outro endpoint se um deles ficar indisponível. O Azure Traffic Manager é útil para cenários em que pretende melhorar a experiência do utilizador reduzindo a latência, aumentar a fiabilidade da sua aplicação fornecendo redundância ou apoiar a recuperação de desastres mudando para uma região de backup.

## Métodos de roteamento do Traffic Manager

Existem hoje 6 métodos de roteamento para o Azure Traffic Manager para determinar como rotear o tráfego de rede aos vários pontos de extremidade de serviço. O Traffic Manager aplica o método de roteamento de tráfego associado a cada perfil para cada consulta DNS recebida. O método de roteamento de tráfego determina qual ponto de extremidade é retornado na resposta DNS.

Os seguintes métodos de roteamento de tráfego estão disponíveis no Azure Traffic Manager:

- **Prioridade:** quando desejar ter um ponto de extremidade de serviço primário para todo o tráfego. É possível fornecer vários pontos de extremidade de backup caso o primário ou um dos pontos de extremidade de backup não estejam disponíveis.

![azure-traffic-manager-priority](/assets/img/13/priority.png){: width="600" height="600" }

- **Ponderado:** quando desejar distribuir o tráfego entre um conjunto de pontos de extremidade com base em seu peso. Defina o peso a ser distribuído uniformemente entre todos os pontos de extremidade.

<img src="/assets/img/13/weighted.png" alt="azure-traffic-manager-weighted" width="600" height="600">

- **Desempenho:** quando tiver pontos de extremidade em diferentes regiões e quiser que os usuários finais usem o ponto de extremidade "mais próximo" para menor latência de rede.

<img src="/assets/img/13/performance.png" alt="azure-traffic-manager-performance" width="600" height="600">

- **Geográfico:** para direcionar os usuários a pontos de extremidade específicos (Azure, externo ou aninhado) com base no local onde suas consultas DNS são originadas geograficamente. Com esse método de roteamento, ele permite que você esteja em conformidade com cenários como mandatos da soberania de dados, localização de conteúdo & experiência do usuário e medição do tráfego de diferentes regiões.

<img src="/assets/img/13/geographic.png" alt="azure-traffic-manager-geographic" width="600" height="600">

- **Vários valores:** para os perfis do Gerenciador de Tráfego que podem ter apenas endereços IPv4/IPv6 como pontos de extremidade. Quando uma consulta for recebida para este perfil, todos os pontos de extremidade íntegros serão retornados.

- **Sub-rede:** para mapear conjuntos de intervalos de endereços IP do usuário final para um ponto de extremidade específico. Quando uma solicitação for recebida, o ponto de extremidade retornado será o mapeado para o endereço IP de origem da solicitação. 

## Criar um Azure Traffic Manager

Para esse exemplo iremos usar o método de roteamento de **Desempenho (Performance)** onde testaremos o acesso de lugares diferentes para que ele faça o roteamento de acordo com a menor latência. Para criar o recurso temos que escolher na barra de pesquisa **Load Balancer** e no menu lateral escolher **Traffic Manager** depois **"+ Create"**, a criação do Azure Traffic Manager é bem simples e com poucos campoas a serem preenchidos:

![azure-traffic-manager](/assets/img/13/01.png)

<hr>

![azure-traffic-manager](/assets/img/13/02.png)

Após preencher os campos, clicar no botão **"Create"** para iniciar a criação do Azure Traffic Manager.

Com o Azure Traffic Manager criado, podemos ver no overview as informações do recurso, a informação mais importante é o DNS Name, como o Traffic Manager é um load balancer baseado em consultas DNS você usará esse DNS para acessá-lo.

![azure-traffic-manager](/assets/img/13/03.png)

> Caso precise de algo personalizado você pode criar uma entrada CNAME no seu registro DNS apontando para o DNS Name do Traffic Manager.
{: .prompt-info }

## Adicionar os Endpoints ao Azure Traffic Manager

Eu prefiro começar a configuração pelos endpoints, os endpoints são para onde o Traffic Manager irá direcionar o tráfego de acordo com o método de roteamento. Acho mais fácil começar por aqui pois sabendo para onde o tráfego será direcionado você já irá saber o ***protocolo***, a ***porta***, o ***path*** e outros itens pertinentes a configuração posterior.

Para isso devemos clicar no menu lateral na opção **"Endpoints"** => **" + Add "**, com isso teremos a tela abaixo para criar o primeiro endpoint:

![azure-traffic-manager](/assets/img/13/04.png)

- Vamos passar pelos itens mais importantes, o primeiro item que devemos escolher é o tipo de endpoint, são 3 tipos disponiveis:

    - **Azure endpoint:** são usados para os serviços hospedados no Azure.
    - **External endpoint:** são usados para endereços IPv4/IPv6, nomes de domínio totalmente qualificados (FQDNs) ou para serviços hospedados fora do Azure. Esses serviços podem estar no local ou com um provedor de hospedagem diferente.
    - **Nested endpoint:** são usados para combinar os perfis do Gerenciador de Tráfego para criar esquemas de roteamento de tráfego mais flexíveis para suportar as necessidades de implantações maiores e mais complexas.

- Precisamos digitar um nome para identificar o endpoint, o nome não é único mas deve ser algo que possa identificar facilmente o que se refere.

- Deveremos marcar se esse endpoint está habilitado ou não.

- Dependendo do tipo de endpoint que você escolher após o nome terão opções diferentes:

    - **Azure endpoint:**

    ![azure-traffic-manager](/assets/img/13/06.png)

    - **External endpoint:**

    ![azure-traffic-manager](/assets/img/13/07.png)

    - **Nested endpoint:**

    ![azure-traffic-manager](/assets/img/13/08.png)

E por fim clicamos no botão **"Add"**, devemos repetir esse passo para todos os endpoints que terão o tráfego balanceado pelo Azure Traffic Manager.


## Configurar o Azure Traffic Manager

Na parte de configuração iremos configurar comoo Azure Traffic Manager irá **validar e monitorar** os endpoints, para isso temos as seguintes opções:

- **Routing method:** aqui escolhemos qual o método de roteamento que precisamos.
- **DNS time to live (TTL)** definimos o tempo em segundos para atualização do cache da consulta DNS.
- **Endpoint monitor settings:** iremos escolher como o endpoint está recebendo consultas, ou seja, qual o protocolo (HTTP, HTTPS ou TCP), qual porta e qual path (caminho) ele está respondendo, por padrão é a raiz "/".
- **Tolerated number of failures:** númeor tolerável de falhas para considerar o endpoint indisponível.
- **Probe timeout** tempo em segundos para considerar o timeout.

Abaixo segue uma imagem da tela de configuração:

![azure-traffic-manager](/assets/img/13/05.png)

<hr>

Após termos configurado como "testamos" e "monitoramos" os endpoints, o status desejado é **on-line**, ou seja, o endpoint está apto a receber o tráfego.

![azure-traffic-manager](/assets/img/13/09.png)

Nesse exemplo configuramos o método de roteamento baseado em performance (latência), então ele irá direcionar o tráfego para o endpoint que responde mais rápido a solicitação.

## Concluindo!

O Azure Traffic Manager tem evoluido durante esses anos, quando estudei para o exame AZ-303, se a memória não falha, não era possível usarmos um endpoint com IPs, podiamos somente indicar um domínio FQDN. Com isso ele se tornou uma ótima opção para um Load Balancer externo com endpoints com IPs públicos.

Eu já usei o Azure Traffic Manager como host para uma VPN, usando o método de roteamento por peso (Ponderado) deixando o maior peso para o link de internet principal e um peso menor em caso de falha do link principal para o link de internet secundário.

Bom pessoal, espero que tenha gostado e que esse artigo seja util a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/pt-br/azure/traffic-manager/traffic-manager-endpoint-types" target="_blank">Pontos de extremidade do Gerenciador de Tráfego</a> 

<a href="https://learn.microsoft.com/pt-br/azure/traffic-manager/traffic-manager-monitoring" target="_blank">Monitoramento de ponto de extremidade do Gerenciador de Tráfego</a> 

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
<hr>
---
title: "Rede Hub-Spoke no Azure usando o Linux como roteador (NVA - Network Virtual Appliance)"
date: 2025-04-05 01:33:00
categories: [Azure]
tags: [azure, linux]
slug: 'linux-as-router-azure'
image:
  path: assets/img/35/35.webp
---

Olá pessoal! Blz?

Nesse artigo quero compartilhar algo sobre redes no Microsoft Azure, sabemos que o uso de rede Hub-Spoke é uma das topologias de rede recomendadas pelo Cloud Adoption Framework (CAF) da Microsoft. Quero trazer nesse artigo um resumo sobre essa recomendação e sobre roteamentos entre redes virtuais, para esse roteamento usaremos um **Network Virtual Appliance (NVA) com Linux.**

Eu tenho um ambiente de estudos/laboratório onde eu aplico essa topologia, mas sempre estava precisando criar uma máquina virtual Windows para a função de roteador, eu usava o **Routing and Remote Access Service (RRAS)** no Windows Server para realizar esse roteamento.

Como uma máquina virtual com Windows exige um tamanho com melhores recursos de vCPU e memória RAM, eu sempre apagava a máquina virtual quando não precisava mais, até que chegou um ponto que eu só deixava ela desligada e ligava quando precisasse.

> Meu ambiente de testes e laboratório são créditos **limitados** que eu recebo da Microsoft e então poupar é uma preocupação.
{: .prompt-info }

Só que de uma certa forma eu não gostava disso, acredito que todos nós fazemos laboratório de testes e estudos de uma maneira que fique o mais próximo da realidade, digo em relação a ambientes que temos em empresas, e em empresas **"geralmente"** temos um firewall ou algum dispositivo fazendo o papel de roteador entre as redes. Então pensei: ***"Não quero ter que ligar e desligar a máquina virtual toda vez que for realizar algo, quero algo que fique ligado sempre, assim como temos em ambientes corporativos."*** Com esse pensamento eu pensei em manter uma máquina virtual de tamanho pequeno para manter um Linux realizando esse papel de roteador, como o Linux não tem interface gráfica eu não precisaria de tantos recursos computacionais.

> Mas primeiro vamos falar um pouco sobre a arquitetura de rede que temos no Microsoft Azure.
{: .prompt-tip }

## Rede Hub-Spoke no Microsoft Azure

A topologia de rede é um elemento crítico de uma arquitetura porque define como os aplicativos podem se comunicar uns com os outros. No modelo Hub-spoke temos uma rede virtual Hub que atua como um ponto central conectando outras redes virtuais spoke. A rede virtual do hub hospeda serviços compartilhados do Azure. Os workloads hospedadas nas redes virtuais spoke podem usar esses serviços. A rede virtual de hub é o ponto central da conectividade entre redes locais, abaixo temos uma arquitetura que ilustra essa topologia de rede:

![azure-hub-spoke](/assets/img/35/01.png){: .shadow .rounded-10}

Com a rede virtual **Hub** temos os seguintes benefícios:

- **Gateway**: a capacidade de conectar e integrar diferentes ambientes de rede uns aos outros. Esse gateway geralmente é uma VPN ou um circuito do ExpressRoute.

- **Controle de saída**: o gerenciamento e o controle do tráfego de saída que se origina nas redes virtuais spoke emparelhadas.

- **Controle de entrada**: o gerenciamento e o controle do tráfego de entrada para pontos de extremidade que existem em redes virtuais spoke emparelhadas.

- **Roteamento**: gerencia e direciona o tráfego entre o hub e os spokes conectados para habilitar a comunicação segura e eficiente.

Nas redes **spokes** podemos isolar workloads/aplicações, e se caso precise se comunicar com outro workload em outra rede spoke o roteamento é feito pela rede **Hub**.

## Roteamento entre as redes virtuais com um NVA

Se você precisar de conectividade entre spokes, podemos implementar um firewall outro NVA no hub, e depois criamos rotas para encaminhar o tráfego de um spoke para o firewall ou NVA, que pode então rotear para o segundo spoke, para isso precisamos ***configurar o peering somente das redes spokes com a rede Hub e não entre os spokes.***

Na imagem abaixo queremos da **rede spoke B** ir até algum recurso da **rede spoke A**, podemos ver esse tráfego pela <span style="color:green">**seta verde**</span>, para isso encaminhamos o tráfego para a rede Hub e o firewall/NVA faz o roteamento do tráfego para a rede spoke A:

![azure-hub-spoke](/assets/img/35/02.png){: .shadow .rounded-10}

## Ambiente proposto para esse laboratório

Pessoal, não quero deixar o artigo comprido, pois eu gosto de artigos curtos e direto ao ponto, portanto, não entrarei em detalhes de criação da rede virtual Hub, as redes virtuais Spoke, os peering entre elas e a criação da máquina virtual Linux, peço desculpas por isso!!!

A arquitetura que uso em meus ambientes é parecida como a da imagem abaixo, trocando somente os nomes dos recursos para fazer mais sentido com o que estou testando e/ou estudando:

![azure-hub-spoke](/assets/img/35/03.svg){: .shadow .rounded-10}

### Peering entre as redes virtuais

Configurado o peering entre a rede virtual Hub e os as redes virtuais spokes:

![azure-hub-spoke](/assets/img/35/04.png){: .shadow .rounded-10}

Ao criar o peering entre as redes virtuais, hub e spokes, precisamos habilitar o encaminhamento de tráfego nos dois lados do peering:

![azure-hub-spoke](/assets/img/35/08.png){: .shadow .rounded-10}

### Network Security Group 

Precisamos ter um NSG (Network Security Group) associado a subnet ou placa de rede onde a máquina virtual que será o nosso roteador está configurada permitindo o tráfego vindo das redes virtuais que estão conectadas por peering:

![azure-hub-spoke](/assets/img/35/09.png){: .shadow .rounded-10}

## Usando um servidor linux como roteador / NVA

Como falei na introdução o objetivo é usarmos uma máquina virtual Linux para fazer o roteamento do tráfego das redes virtuais, para isso eu criei um servidor Ubuntu 24.04 na rede virtual Hub, ou seja, todo o tráfego de rede que for para fora da rede virtual será encaminhado para esse servidor:

![azure-hub-spoke](/assets/img/35/07.png){: .shadow .rounded-10}

### Habilitando o encaminhamento de tráfego

Uma configuração que precisamos fazer é habilitar o **encaminhamento de tráfego** na placa de rede da máquina virtual para ele encaminhar todo o tráfego que passe por ela:

![azure-hub-spoke](/assets/img/35/06.png){: .shadow .rounded-10}

### Tamanho da máquina virtual

Como falei acima a minha idéia era criar um servidor com o papel de NVA e deixá-lo sempre ligado, mas para isso eu precisava que o custo não fosse alto, pois tenho uma quantidade limitada de créditos mensais, e a performance estivesse ok.

Estou rodando esse cenário já a algumas semanas e no tamanho de máquina virtual mínimo tem atendido ao meu ambiente onde sempre existem no máximo 10 (dez) máquinas virtuais se comunicando entre si, e como falei o ambiente é usado para estudos e laboratório, então não tenho percebido gargalos.

Para esse ambiente estou usando o tamanho de máquina virtual **B1ls**, que conta com apenas **1 (um) vCPU e 0.5 Gb de memória RAM** e no momento que escrevo esse artigo tem custado **R$ 25,91 mensais.**

![azure-hub-spoke](/assets/img/35/13.png){: .shadow .rounded-10}

O uso de memória RAM tem ficado no limite mas sem comprometer a função de roteador, então por enquanto vou seguir como está.

### Comandos para tornar o servidor Linux um roteador

Com a parte da configuração pronta no portal do Microsoft Azure precisamos agora configurar o Linux para atuar como roteador, devemos executar os seguintes comandos na máquina virtual:

```bash
sudo apt update && sudo apt upgrade -y
sudo sed -i 's/#net\.ipv4\.ip_forward=1/net\.ipv4\.ip_forward=1/g' /etc/sysctl.conf
sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt install -y iptables-persistent
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables-save | sudo tee -a /etc/iptables/rules.v4

echo '#!/bin/bash
sudo /sbin/iptables-restore < /etc/iptables/rules.v4
sudo ip route add 168.63.129.16 via 10.162.0.1 dev eth1 proto dhcp src 10.162.0.4

# Redes virtuais spokes
sudo ip route add 10.163.0.0/16 via 10.162.0.1 dev eth1
sudo ip route add 10.164.0.0/16 via 10.162.0.1 dev eth1 
' | sudo tee -a /etc/rc.local && sudo chmod +x /etc/rc.local

sudo reboot 
```

>Nos comandos que executamos temos duas linhas que correspondem as redes virtuais spokes, se você tiver mais redes você deve adicioná-las.
{: .prompt-tip }

## Route table direcionando o tráfego das redes spokes para a rede Hub

Foi criado uma route table para cada rede virtual spoke e associado a subnet:

![azure-hub-spoke](/assets/img/35/05.png){: .shadow .rounded-10}

Precisamos agora configurar as rotas para onde queremos encaminhar o tráfego de rede, por exemplo, para irmos da rede spoke **vnet-spoke-westus-01** `10.163.0.0/16` para a rede spoke **vnet-spoke-westus-02** `10.164.0.0/16` devemos configurar a rota direcionando para o IP da máquina virtual Linux que está atuando como roteador `10.163.0.4`.

Também queremos que o tráfego de internet saia pela NVA e para isso criamos uma regra direcionando todo o tráfego para `0.0.0.0/0` para o servidor Linux `10.163.0.4`.

![azure-hub-spoke](/assets/img/35/10.png){: .shadow .rounded-10}

## Testando o ambiente

Para ver se a saída para a internet esta saindo com o IP público da máquina virtual Linux (NVA) podemos usar o comando `curl http://ipv4.icanhazip.com` e o com isso podemos confirmar que estamos saindo pela máquina virtual Linux e também podemos testar se conseguimos chegar até a máquina virtual da rede spoke:

![azure-hub-spoke](/assets/img/35/11.png){: .shadow .rounded-10}

![azure-hub-spoke](/assets/img/35/12.png){: .shadow .rounded-10}

## Concluindo!

Nesse exemplo deixamos o nosso ambiente bem parecido como funciona em ambientes grandes e corporativos, claro que em ambientes grandes teremos um firewall fazendo esse papel, mas pelo menos ter um roteador central controlando o tráfego e saída para internet nos ajuda a ter um controle maior e um único ponto de gerenciamento e com isso deixando nossos laboratórios bem mais "reais".

Bom pessoal, eu tenho usado isso em alguns ambientes e acredito que possa ser bem útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/pt-br/azure/architecture/networking/architecture/hub-spoke" target="_blank">Topologia de rede hub-spoke no Azure</a>

<a href="https://learn.microsoft.com/pt-br/azure/virtual-network/virtual-networks-udr-overview" target="_blank">TRoteamento de tráfego de rede virtual</a>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!


![outbound-internet-azure](/assets/img/34/05.png){: .shadow .rounded-10}
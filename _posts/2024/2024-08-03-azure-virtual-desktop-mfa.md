---
#layout: post
title: 'Como forçar o MFA em sessões do AVD usando Acesso Condicional' 
date: 2024-08-02 11:33:00
categories: [Azure, Security]
tags: [azure, security, avd, entraid]
slug: 'azure-virtual-desktop-mfa-enforced'
image:
  path: /assets/img/18/18-header.webp
---

Olá pessoal! Blz?

Nesse artigo eu quero trazer uma configuração para forçar o uso do **MFA (Multi-factor authentication)** em sessões do **Azure Virtual Desktop (AVD)** para garantir uma segurança maior quando os usuários acessarem esse serviço.

O Azure Virtual Desktop é um serviço do Microsoft Azure de área de trabalho remota, onde podemos disponibilizar um desktop virtual inteiro para o usuário ou apenas disponibilizar algumas aplicações para realizar o seu trabalho. E com o uso do AVD, o usuário pode acessar o ambiente de trabalho ou uma aplicação de qualquer lugar, ou seja, fora do ambiente da empresa, e consequentemente em um ambiente que não podemos controlar, usar alguns recursos para garantir uma segurança maior é sempre bem vindo!

Para essa configuração iremos usar o recurso de **Acesso Condicional** do Azure Entra ID, para isso precisaremos de licenças P1 ou P2 habilitadas no tenant. Se você for realizar testes de acesso condicional ou outras configurações de segurança em seu ambiente você pode habilitar o trial das licenças por 30 dias. Para isso siga os seguintes passos **nesse link**.

![azure-avd-mfa](/assets/img/18/18-thumbnail.png)

## Criando a política de Acesso Condicional

As políticas de Acesso Condicional em sua forma mais simples são instruções **if-then;** Se um usuário quiser acessar um recurso, ele deverá concluir uma ação. Por exemplo: no nosso caso desse artigo se um usuário quiser acessar a área de trabalho remota do AVD, ele deverá executar a autenticação multifator para obter acesso. As políticas de Acesso Condicional são aplicadas após a conclusão da autenticação de primeiro fator, ou seja, primeiro é feita a autenticação em forma de "usuário e senha" (pode haver outras formas de autenticação) e depois disso é aplicada a política de acesso condicional relacionada ao serviço configurado.

Para criarmos uma política de acesso condicional, na barra de pesquisa do Microsoft Azure podemos digitar ***"conditional"*** que ele trará a opção abaixo:

![azure-avd-mfa](/assets/img/18/01.png)

Depois devemos clicar na opção **"+ Create new policy"** para começarmos a criação da nossa política:

![azure-avd-mfa](/assets/img/18/01a.png)

Na tela de configuração da política de acesso condicional há várias opções de personalização e configuração, mas nesse exemplo iremos focar somente no propósito do artigo.

No primeiro campo precisamos digitar um nome que facilite a identificação e propósito da política, no nosso exemplo escolhemos o nome: **mfa-avd-required**, logo após temos que identificar quais usuários e/ou grupos farão parte dessa política conforme o item **2**, eu quando trabalho com o AVD crio 2 grupos, um grupo para os administradores e outro grupo para os usuários pois fica mais fácil administrar quem é quem dentro do AVD e qual tipo de acesso, por isso escolhemos **"Select users and groups"** no item **3** e clicar para escolher os grupos no item **4** conforme abaixo:

![azure-avd-mfa](/assets/img/18/02.png)

Na tela de escolher quais usuários ou grupos farão parte da política o mais fácil é digitar na barra de busca e com o resultado escolhido selecionar e clicar em **"Select"**.

![azure-avd-mfa](/assets/img/18/03.png)

O próximo item a ser configurado é o **"Target resources"**, que são quais as aplicações farão parte da política, no nosso caso iremos escolher os 2 itens abaixo:

- **Azure Virtual Desktop**: que se aplica quando o usuário assina a Área de Trabalho Virtual do Azure, autentica no Gateway de Área de Trabalho Virtual do Azure durante uma conexão.

- **Microsoft Remote Desktop**: se aplica quando o usuário se autentica no host da sessão quando o single sign-on está habilitado.

![azure-avd-mfa](/assets/img/18/04.png)

Não sei porque mesmo digitando na busca ***"Desktop"*** não traz as 2 opções, portanto tem que repetir o passo novamente para adicionar a outra opção:

![azure-avd-mfa](/assets/img/18/04a.png)

Agora em **Conditions** iremos escolher qual a condição aceitaremos o usuário utilizar o AVD, para isso escolheremos **Client apps** e na tela que abre a direita escolheremos **Browser** e **Mobile apps and desktop clients**, que será permitido o usuário acessar o AVD a partir de um navegador ou com o client do AVD.

![azure-avd-mfa](/assets/img/18/08.png)

Próximo passo é **Grant**, onde informaremos se o acesso será permitido e de que forma a aplicação escolhida acima será acessada, temos duas opções: **Block access** e **Grant access**, nesse caso iremos escolher **Grant** porque queremos liberar o uso da aplicação, mas devemos escolher o item abaixo **Require multifactor authentication**, ou seja, o acesso será permitido, mas somente com o uso do ***MFA (multifactor authentication).***

![azure-avd-mfa](/assets/img/18/05.png)

No item **Session** iremos definir a frequência que iremos solicitar o MFA dando um clique e assinalando a opção: **Sign-in frequency**, onde temos duas opções de escolha:

- **Periodic reauthentication**: onde podemos definir quantas **horas** ou **dias** iremos solicitar novamente o MFA, por exemplo, o usuário entrou agora no AVD e fez o que tinha que fazer e saiu, se ele entrar novamente dentro do período de 1 hora não será solicitado o MFA novamente.

- **Every time**: como o nome já diz, toda vez que o usuário entrar no AVD será solicitado o MFA a ele.

![azure-avd-mfa](/assets/img/18/06.png)

E agora o item mais importante que é o que faremos com a política que acabamos de criar, e aqui temos três opções dentro de **Enable policy**:

- **Report-only**: somente será gerado um relatório do acesso
- **On**: a política está ativada
- **Off**: a política está desativada

Devemos escolher a opção **On** para que seja aplicada a política de Acesso condicional que acabamos de criar.

![azure-avd-mfa](/assets/img/18/07.png)

## Concluindo!

Com a política que criamos nesse artigo uma camada extra de segurança foi adicionada ao nosso ambiente de AVD, e agora podemos dormir um pouco mais tranquilos com um recurso "exposto" 😊.

Irei trazer mais alguns artigos sobre AVD que é um recurso do Microsoft Azure muito interessante e que gosto muito!!

Bom pessoal, espero que tenha gostado e que esse artigo seja útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/overview" target="_blank">What is Conditional Access?</a> 

<a href="https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-policies" target="_blank">Building a Conditional Access policy</a> 


Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!

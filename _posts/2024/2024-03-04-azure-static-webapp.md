---
title: 'Azure Static Web App para hospedagem de sites/blogs gratuitamente'
date: 2024-03-04 10:33:00
slug: 'azure-static-webapp'
categories:  ['Azure']
tags: ['Azure', 'Blog', 'Azure Devops', 'GitHub']
image:
  path: assets/img/04/04-header.webp
---

Olá pessoal! Blz?

Quando decidi criar um blog comecei a pensar em um gerenciador de conteúdo pensei no Wordpress, mas logo no começo a lentidão já me deixou desanimado, comecei a pesquisar sobre sites estáticos que para um começo já seria mais que suficiente, e com isso eu poderia hospedar em uma Azure Storage Account de maneira fácil. Mas comecei a ler sobre o Azure Static Web App que conta com um plano Free e essa palavra **"free"** salta aos meus olhos 😊 😜.

## O que é o Azure Static WebApp?

O Azure Static Web App é um serviço de hospedagem na Web para conteúdo estático, como HTML, CSS, JavaScript e imagens, e o mais legal na minha opinião nesse recurso é a possibilidade de interagir diretamente com o Azure Devops e GitHub.

Sempre que você efetua push de commits para a branch em que você está trabalhando um build é executado automaticamente, é executada uma pipeline de deploy no GitHub Actions ou Azure Devops e o seu site/blog é atualizado no Azure automaticamente.

![staticwebapp](/assets/img/04/01.png)

## Qual plano escolher para o seu Azure Static Web App

O Azure Static Web App tem disponível dois planos diferentes, Gratuito (free) e Standard, na própria descrição no Portal do Azure já é mencionado a recomendação para cada tipo de uso.

O plano é escolhido no momento da criação e a escolha é baseado no propósito que você esteja criando seu site/blog, a seguir imagem da escolha do plano e a tabela de comparação entre os planos:

![staticwebapp](/assets/img/04/02.png)

![staticwebapp](/assets/img/04/03.png)

 Claro que o plano gratuito tem performance inferior ao Standard, caso voce queira alternar entre os planos após o recurso criado você pode fazer isso escolhendo a opção **Hosting Plan** na blade **Settings.** 

![staticwebapp](/assets/img/04/10.png)

E depois de escolher o plano, clicar no botão **Salvar**

## Onde será implantado o código (GitHub, Azure Devops ou Outros)

No momento em que está criando o recurso você pode escolher onde manterá seu código (website), se sua escolha for entre GitHub e Azure Devops o Azure irá configurar a pipeline de deploy com um código yaml para automatizar o deploy do seu website logo na criação do recurso.

![staticwebapp](/assets/img/04/04.png)

## Domínio personalizado

Outra feature interessante no Azure Static Web App é a possibilidade de configurar um domínio personalizado para o seu site, nos 2 planos temos essa possibilidade e a configuração é simples, temos que apenas incluir um registro CNAME ou TXT em nosso gerenciador de DNS.

![staticwebapp](/assets/img/04/09.png)

## Como eu uso o Azure Static Web App?

Para manter esse blog eu uso o <a href="https://gohugo.io/" target="_blank">HUGO</a> que é um gerador de website estático, vou deixar alguns links abaixo para referência, com ele eu crio os artigos em Markdown, faço as revisões em meu ambiente (localhost) e se tudo estiver da forma que quero realizo o push para a minha branch no GitHub e com isso a pipeline de deploy é iniciada automaticamente.

Eu tenho usado o modo **Gratuito**,  **domínio personalizado** que voce pode ver no campo URL e implantado por pipelines no **GitHub**, com isso além de ter o benefício do versionamento conto ainda como uma forma de "backup" do website:

![staticwebapp](/assets/img/04/08.png)

Abaixo o GitHub Actions em ação após eu "commitar" o código com as alterações e/ou adição de novos artigos:

![staticwebapp](/assets/img/04/05.png)

![staticwebapp](/assets/img/04/06.png)

![staticwebapp](/assets/img/04/07.png)

Após o término o blog esta atualizado com a última versão em um pouco mais de 1 minuto.

## Concluindo!

Bom pessoal, quis trazer a vocês esse recurso que uso diariamente para manter esse blog e que apesar de usar a versão gratuita tem me atendido em tudo que preciso, o que acho mais bacana e me tira um pouco da zona de conforto é ter que escrever artigos em Mardown ja que essa linguagem é altamente usada para documentar repositórios GIT, e mesmo que não tenha sido eu que configurei 😆😆 tenho uma pipeline funcional no GitHub Actions.

## Artigos relacionados

<a href="https://learn.microsoft.com/pt-br/azure/static-web-apps/overview" target="_blank">O que é o Azure Static Web App?</a>

<a href="https://learn.microsoft.com/pt-br/azure/static-web-apps/publish-hugo" target="_blank">Implantar um site do Hugo com azure Static Web App</a>

Bom pessoal, espero que tenha gostado e que esse artigo seja útil a voces!

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
<hr>
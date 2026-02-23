---
title: "Azure WebApp: Custom Domain e certificado SSL gratuito em sua aplicação Web"
date: 2025-11-15 01:00:00
categories: [Azure]
tags: [azure]
slug: 'azure-web-app-custom-domain-certificate'
image:
  path: /assets/img/47/47-header.webp
---

Olá pessoal! Blz?

No artigo de hoje gostaria de trazer uma dica para quem gostaria de hospedar seu website pessoal ou uma aplicação no **Azure WebApp**, ter seu **domínio personalizado** (Custom Domain) e também um **certificado SSL** gratuito.

Quando criamos um Azure Webapp é gerado uma URL padrão com o nome do WebApp mais o domínio da Microsoft como por exemplo: arantes-bba7gpexf5aqdgeq.eastus2-01.***azurewebsites.net*** o que para ambiente de testes não teria nenhum problema mas para o dia a dia não fica uma URL tão fácil ou bonita, ainda mais agora com o sufixo que a Microsoft sugere colocar durante a criação do recurso.

![azure-web-app-custom-domain-certificate](/assets/img/47/01.png){: .shadow .rounded-10}

Para mudar isso é possível adicionarmos um domínio personalizado e também um certificado SSL para ter um site seguro, para isso claro você vai precisar ter um domínio próprio, seja ele no registro.br, na hostinger, godaddy ou outro vendedor de domínio na internet.

Para fazer isso iremos fazer 2 configurações, a primeira será para criar um domínio personalizado e depois validar e criar um certificado SSL.

## Adicionando um domínio personalizado

Como falei acima, é primordial você ter um domínio próprio pois é necessário realizar uma validação para confirmar que você realmente é proprietário do domínio.

Para fazer essa configuração devemos ir no Azure WebApp em ***Custom domains*** -> ***+ Add custom domain***:

![azure-web-app-custom-domain-certificate](/assets/img/47/02.png){: .shadow .rounded-10}

<b>

Com a janela que se abre devemos escolher as opções conforme a imagem abaixo e a explicação do que porque das opções:

- **Domain provider**: escolhemos a opção **All other domain services** para podermos especificar qual sera o domínio que iremos adicionar.

- **TLS/SSL certificate**: a opção **App Service Managed Certificate** para que o Azure ja coloque um certificado SSL para o domínio que queremos usar.

- **Domain**: qual será o domínio personalizado que teremos para o Azure WebApp.

![azure-web-app-custom-domain-certificate](/assets/img/47/03.png){: .shadow .rounded-10}

<b>

Eu separei as tarefas mas na verdade fazem parte da mesma configuração acima, separei para ficar de forma mais clara!

Agora precisamos criar 2 registros DNS em nosso domínio para "provar" que somos propeietários do domínio, isso é uma segurança para não sairmos adicionando domínios por ai 😆.

No gerenciador de DNS de onde está localizado nosso domínio precisamos criar 2 registros, 1 registro do tipo **CNAME** e outro do tipo **TXT**:

![azure-web-app-custom-domain-certificate](/assets/img/47/04.png){: .shadow .rounded-10}

<b>

Depois de criados os registro temos que clicar no botão **Validar** para que o Azure verifique a existência dos registro e prossiga com a configuração clicando no botão **Add**.

E com isso é criado o certificado, feito o binding e com isso já temos um domínio personalizado:

![azure-web-app-custom-domain-certificate](/assets/img/47/05.png){: .shadow .rounded-10}

<b>

Com isso podemos ver no navegado o nosso site já com o certificado:

![azure-web-app-custom-domain-certificate](/assets/img/47/06.png){: .shadow .rounded-10}


## Concluindo!

Configurar um domínio personalizado no **Microsoft Azure App Service e habilitar o certificado SSL gratuito** é uma forma simples e eficiente de tornar sua aplicação mais profissional e segura.

Com poucos passos, você **garante HTTPS**, aumenta a credibilidade do seu site e elimina custos com certificados pagos — tudo aproveitando os recursos nativos do Azure.

Um ajuste pequeno na configuração, mas um grande avanço em segurança e confiança.

## Artigos relacionados

<a href="https://learn.microsoft.com/en-us/azure/app-service/app-service-web-tutorial-custom-domain?tabs=root%2Cazurecli" target="_blank">Set up an existing custom domain in Azure App Service</a>

<a href="Overview: Use custom domain names with Azure App Service" target="_blank">Overview: Use custom domain names with Azure App Service</a>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
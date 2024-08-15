---
#layout: post
title: 'Usando certificado SSL (HTTPS) em serviços locais (homelab) com Nginx Proxy Manager' 
date: 2024-08-15 11:33:00
categories: [Homelab]
tags: [Homelab, nginx, devops]
slug: 'nginx-proxy-manager-homelab'
image:
  path: assets/img/19/19-header.webp
---

Olá pessoal! Blz?

Nesse artigo eu quero trazer como eu uso sites **HTTPS** nos serviços que eu rodo em meu homelab, sem isso ficava tendo aqueles avisos chatos de ***site não seguro*** e para clicar no botão para continuar. Com isso eu não preciso ficar decorando os IPs dos servidores e posso acessá-los através do nome que eu definir.

Para isso estou utilizando o **Nginx Proxy Manager**, é um software de código aberto que simplifica a configuração e gerenciamento, atuando como um proxy reverso com SSL. Você pode conferir o site do projeto em <a href="https://nginxproxymanager.com/" target="_blank">Nginx Proxy Manager</a> 

## Pré requisitos

Para configurar o nosso ambiente para esse propósito temos alguns requisitos, e precisamos usar um domínio público para isso, estou usando o que já possuo mas você pode estar usando por exemplo o <a href="https://www.duckdns.org/" target="_blank">Duck DNS</a> que é gratuito.

E claro, precisará rodar o serviço em algum servidor, eu estou usando ele em forma de container, por ser mais prático de gerenciar e não ter um servidor a mais para manter.

## Instalação

Como falei estou usando o serviço em container e usando o docker compose através do portainer para subir a stack, deixarei abaixo o docker compose que estou usando em meu ambiente:

```yaml
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
```
<br>

Se tudo estiver ok teremos um container rodando e escutando nas portas que definimos na stack, conforme imagem abaixo:

![nginx-proxy-manager](/assets/img/19/01.png)

## Acessar o Nginx Proxy Manager

Para acessar o serviço devemos usar o IP do servidor que está hospedando o serviço ou o host de container na porta 81: **http://192.168.1.14:81**

Na primeira vez teremos que usar as seguintes credenciais:

```
Email:    admin@example.com
Password: changeme
```

Imediatamente após fazer login com este usuário padrão, você será solicitado a modificar seus dados e alterar sua senha.

## Configurar Nginx Proxy Manager

Ao acessar temos o Dashboard onde traz um resumo do que temos configurado, e um menu do que podemos configurar:

![nginx-proxy-manager](/assets/img/19/02.png)

Vamos preparar nosso ambiente, primeiro criando o certificado e depois criando os hosts.

### 1 - Configurar o Certificado SSL

Vamos definir o certificado SSL que iremos usar em nossos hosts e serviços, para isso devemos ir no menu SSL Certificates e clicando no botão **Add SSL Certificate**:

![nginx-proxy-manager](/assets/img/19/03.png)

Iremos usar o Let's Encrypt para gerar o certificado para nós e a configuração é simples, os campos que iremos preencher ou configurar são:

1. **Domain Names:** qual o domínio que iremos usar com o coringa *, no meu caso estou usando **"\*.arantes.net.br"** e clicar em "Add *.arantes.net.br".

2. **Email Address for Let's Encrypt:** e-mail que estará associado a esse certificado/domínio no Let's Encrypt.

3. **Use a DNS Challenge -> DNS Provider:** como não tenho um IP público eu estou usando isso para configurar onde o meu domínio esta hospedado, no meu caso estou usando a Cloudflare e para isso precisamos de um token e iremos preencher no campo correspondente.

4. **I agree to the Let's Encrypt Terms of Service:** concordar com os termos de serviços

5. **Save:** clicar no botão para salvar a configuração que fizemos acima.

![nginx-proxy-manager](/assets/img/19/04.png)

### 2 - Adicionar os Hosts

Agora vamos adicionar os hosts que queremos criar, para isso devemos acessar **Hosts -> Proxy Hosts -> Add Proxy Host**:

![nginx-proxy-manager](/assets/img/19/05.png)

Temos alguns campos que devemos preencher conforme listamos abaixo:

1. **Domain Names:** qual o host e domínio que iremos configurar nesse host, como por exemplo: monitoramento.arantes.net.br depois clicamos no botão **Add monitoramento.arantes.net.br**

2. **Scheme, Forward Hostname / IP e Forward Port:** se para onde iremos direcionar está esperando um serviço http ou https, qual o hostname ou IP e qual a porta que o serviço está configurado.

![nginx-proxy-manager](/assets/img/19/06.png)

Na aba **SSL** temos que escolher na lista qual será o SSL Certificate na lista e clicar na opção **Force SSL** e clicar no botão **Save**.

![nginx-proxy-manager](/assets/img/19/07.png)

### 3 - Listagem dos Hosts

Depois de configurado teremos a lista de todos os hosts que configuramos, onde podemos alterar a configuração clicando no botão destacado abaixo:

![nginx-proxy-manager](/assets/img/19/08.png)

## Testar a configuração

Para testar se deu certo não tem outra opção melhor do que acessar a url no navegador, nesse exemplo vamos usar a url **https://dashboard.arantes.net.br**

![nginx-proxy-manager](/assets/img/19/09.png)

Podemos ver que o site está sendo acessado com o certificado SSL e isso mesmo estando acessando um serviço que não está público e sim interno:

![nginx-proxy-manager](/assets/img/19/10.png)

> O Nginx Proxy Manager não atua como um DNS Server então você precisará resolver o endereço do host de alguma forma.
{: .prompt-warning }

## Concluindo!

Bom pessoal, eu quis compartilhar com vocês como estou usando/acesando os serviços que rodo em meu homelab, e claro que acessando através de nomes é muito mais fácil do que por IP e adicionar uma camada a mais de segurança, seja, ao menos com um certificado SSL é muito melhor.

Bom pessoal, espero que tenha gostado e que esse artigo seja útil a vocês!

## Artigos relacionados

<a href="https://nginxproxymanager.com/" target="_blank">Nginx Proxy Manager</a>

<a href="https://letsencrypt.org/" target="_blank">Let's Encrypt </a> 


Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!

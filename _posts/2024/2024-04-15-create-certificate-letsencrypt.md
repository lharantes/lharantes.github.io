---
title: "Let's Encrypt: Tenha um certificado SSL público para seu ambiente usando docker"
date: 2024-04-15 10:33:00
slug: 'create-certificate-letsencrypt'
categories: ['Devops', 'Docker']
tags: ['Devops', 'LetsEncrypt', 'Docker']
image:
  path: assets/img/09/09-header.webp
---

Olá pessoal! Blz?

Quero nesse artigo demonstrar a vocês como eu faço para gerar um certificado SSL público quando estou testando algum recurso ou fazendo algum laboratório deixando esse o mais próximo da realidade possível. Independentemente de onde esteja criando o recurso mas queira usar um site/serviço HTTPS você precisará de um certificado SSL. 

Ao utilizar recursos como Azure Static site, Azure App Service entre outros é possível criar um certificado e integrar a um domínio personalizdo, mas quando eu realmente preciso do certificado em formato ***.pfx** ai eu não tenho isso fácil/gratuito no Azure e nesses casos eu utilizo o bom e velho Let's Encrypt. O certificado público gerado gratuitamente tem validade de 90 dias mas você pode gerar um outro no fim da validade, segue link do projeto do <a href="https://letsencrypt.org/" target="_blank">Let's Encrypt </a> para que vocês possam consultar também.

![powershell-test-connection](/assets/img/09/00.png)

## O certificado Let’s Encrypt é seguro?

Sim! Isso se dá por conta de uma certificação intermediária que foi assinada pela IdenTrust, que é garantidamente confiável pelos principais navegadores e sistemas operacionais, transmitindo essa credibilidade ao Let’s Encrypt. 

Além disso, eles têm o apoio de grandes empresas de tecnologia, como Google, Microsoft, Facebook, Cisco, Mozilla, entre outras. É pouco provável que essas empresas colocariam suas credibilidades em risco apoiando um projeto inseguro.

## Requisitos para gerar o certificado SSL

Para gerar o certificado usaremos uma imagem docker passando alguns parâmetros, então com isso temos 2 requisitos:

- Ter um domínio público próprio
- Docker instalado no computador/laptop/servidor

> Existem alguns sites onde você pode obter gratuitamente um domínio nem que seja por um curto período de tempo ou 1 ano, segue abaixo 2 opções:
> https://freedomain.one/ <br>
> https://www.hostinger.com/free-domain
{: .prompt-tip }


Caso você ja possua um domínio, para gerar o certificado público é preciso ter acesso a configuração de registros DNS do domínio pois será preciso criar um registro CNAME para "provar" que o domínio pertence a você!!

Para instalar o docker caso você não tenha instalado você pode seguir os passos aqui, <a href="https://docs.docker.com/get-docker/" target="_blank">Instalar docker</a>.

> Para quem estiver usando o Linux ou MacOs o comando abaixo já adianta muito: 
> ```bash
> $ curl -fsSL https://get.docker.com/ | sh
> ```
{: .prompt-tip }

## Como gerar o certificado SSL

Usaremos a imgem de container <a href="https://hub.docker.com/r/zerossl/client/" target="_blank">zerossl/client</a> para gerar o certificado público, para baixar a imagem usamos o comando abaixo:

```bash
$ docker pull zerossl/client
```

Como temos que executar o container e a linha de comando pode ficar muito grande, podemos criar um alias para a primera parte do comando, voce também precisa escolher qual diretório de host você manterá os arquivos e chaves do certificado:

```bash
$ alias docker.zerossl='docker run -it -v /home/luiz/certificate:/data -u $(id -u) --rm zerossl/client'
```

> A sintaxe do comando acima está mapeando uma pasta do meu computador **(/home/luiz/)**, adapte o comando para o seu ambiente. No exemplo acima os arquivos do certificado serão salvos no caminho **"/home/luiz/certificate"**.
{: .prompt-warning }

Agora para solicitar o certifiacdo público para o seu domínio você deve executar o comando a seguir usando o alias criado acima e substitua o <SEU_DOMINIO> pelo seu domínio 😆:

```bash
docker.zerossl --key account.key --csr <SEU_DOMINIO>.csr --csr-key <SEU_DOMINIO>.key --crt <SEU_DOMINIO>.crt --domains "<SEU_DOMINIO>" --generate-missing --handle-as dns --api 2 --live
```

Para esse exemplo, estarei criando um certificado para o domínio **teste.arantes.net.br** e o comando requer a criação do registro DNS que é solicitado na saída do comando acima, vocês podem ver a solicitação com as informações do registro na imagem abaixo e destacado em vermelho:

- **Host:** _acme-challenge.teste.arantes.net.br
- **Tipo:** TXT
- **Valor:** Q4ZguRNhZOLhLyvlrWuPT6yJeBexCPDOsq7jSI3_F1s

Enquanto você não criar esse registro no seu DNS ele não irá gerar o certificado e ficará parado nessa tela aguardando isso:

![powershell-test-connection](/assets/img/09/01.png)
</center>

Após você criar o registro DNS pressione **< ENTER >** na tela do terminal onde foi executado o comando, se o nslookup receber o retorno da consulta DNS o certificado é requisitado e gerado com sucesso:

![powershell-test-connection](/assets/img/09/02.png)

Após a conclusão da solicitação do certificado, você encontrará os seguintes arquivos dentro do diretório que você informou no comando acima:

![powershell-test-connection](/assets/img/09/03.png)

## Gerar o certificado no formato *.pfx 

Para exportar o certificado no formato pfx temos que usar o **openssl** conforme comando abaixo substituindo os parâmetros pelo de vocês: 

```bash
$ openssl pkcs12 -export -out arantes.net.br.pfx -inkey arantes.net.br.key -in arantes.net.br.crt
```

Ele irá pedir a senha do certificado e a confirmação da senha, e com isso, listando o conteúdo do diretório ja temos o certificado pfx.

![powershell-test-connection](/assets/img/09/04.png)

## Receber notificação de expiração por e-mail

Como vocês já sabem os certificados gerados pela Let's Encrypt tem validade de 90 dias, você pode atualizar seus dados de contato no Let's Encrypt (para receber notificações de expiração), para isso você deve usar o comando abaixo usando a flag ***--update-contacts***

```bash
$ docker.zerossl --key account.key --update-contacts "one@email.address" --live
```

Para remover seus dados de contato, use "none" como valor:

```bash
$ docker.zerossl --key account.key --update-contacts "none" --live
```

## Renovar o certificado

Para renovar de forma automática o certificado você pode dar uma olhada em https://certbot.eff.org. Certbot é uma ferramenta de software gratuita e de código aberto para usar automaticamente certificados Let’s Encrypt.

## Concluindo!

Esse artigo será útil para você aplicar em alguns laboratórios, estudos ou em seus projetos pessoais, pois o Let's Encrypt é uma autoridade certificadora reconhecida e com essa ferramenta qualquer pessoa pode emitir um certificado digital para habilitar o HTTPS em seu site.

Logo eu trarei um artigo para automatizar a renovação, mas por enquanto, podem dando uma olhada no certbot que mencionei acima!

Bom pessoal, espero que tenha gostado e que esse artigo seja util a vocês!

## Artigos relacionados

<a href="https://hub.docker.com/r/zerossl/client/" target="_blank">ZeroSSL</a> 

<a href="https://hub.docker.com/r/doknow/crypt-le" target="_blank">Crypt-le</a> 

<a href="https://docs.digitalocean.com/support/how-can-i-renew-lets-encrypt-certificates/" target="_blank">How can I renew Let's Encrypt certificates?</a> 

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
<hr>
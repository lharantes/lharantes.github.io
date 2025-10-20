---
title: 'Problema de ativação do Windows em VMs no Microsoft Azure'
date: 2024-03-19 10:33:00
slug: 'virtual-machine-activation-issue'
categories:  ['Azure']
tags: ['Azure', 'Microsoft Windows']
image:
  path: /assets/img/06/06-header.webp
---

Olá pessoal! Blz?

Em alguns ambientes corporativos no Microsoft Azure muitas vezes se faz necessário um controle maior do tráfego de entrada/saída de internet e de roteamento entre as redes virtuais, para isso geralmente é implementado um NVA (Network virtual appliance) que faz todo esse controle, ou se o controle for apenas de internet, pode direcionar todo o tráfego de internet para um NVA on premises para fazer esse controle. Com isso as empresas ganham um melhor controle do que entra e sai de sua rede, tem um controle melhor do roteamento das redes, ter alguns relatórios disponiveis e outros recursos que podem fazer sentido ao negócio da empresa!

> Para entenderem melhor essa parte sobre NVA e roteamento de redes, vou deixar um link de um vídeo da TFTEC onde o Raphael Andrade demonstra a implementação de um NVA: <a href="https://youtu.be/e8Nx5e7nrDk" target="_blank">Roteamento no Azure com NVA e Route Table</a>


Mas com essa prática além dos beneficios citados podemos ter alguns problemas que só vamos descobrindo aos poucos, digamos assim, mas que seguindo alguns passos e ajustes contornamos isso.

O problema/solução que quero demonstrar a voces hoje nesse artigo é o problema em **ativar a licença do Windows** quando a máquina virtual no Azure está tendo o trafego de saída de internet sendo direcionado a um NVA, e com isso o processo de ativação do Windows falha. Como eu disse acima esse é um problema que descobrimos aos poucos pois pode ser que o problema só seja detectado quando entregamos a máquina virtual para uso.


## Problema ao ativar a licença do Windows no Azure

Ao verificarmos o status da ativação do Windows vemos a mensagem ***Windows is not activated***:

![powershell-test-connection](/assets/img/06/01.png)

Isso acontece porque o servidor KMS para ativação do Windows não pode ser contactado, pois como direcionamos o tráfego saída de internet ao nosso NVA/Firewall ele deve estar bloqueando o acesso. Com o comando abaixo podemos testar a conexão para o endpoint de ativação do windows:

```powershell
Test-NetConnection kms.core.windows.net -port 1688
```

E o resultado nos mostra que realmente não há conexão com o servidor KMS para ativação:

![powershell-test-connection](/assets/img/06/03.png)

## Solução para o problema de conectividade

Para resolver o problema de ativação devemos garantir que as seguintes URLs devem estar liberadas no firewall e ambas na porta 1688:

- kms.core.windows.net:1688
- azkms.core.windows.net:1688

Após a liberação das URLs podemos testar novamente a conexão atraves do powershell com o comando que disponibilizamos acima e se já tivermos com a liberação para as URLs que a Microsoft nos indica devemos ter o seguinte resultado:

![powershell-test-connection](/assets/img/06/02.png)

O bloqueio e/ou não liberação de URLs da Microsoft afeta outros tipos de serviços também, por isso, a Microsoft disponibiliza uma relação de URLs que devemos liberar nos firewalls e servidores proxy quando fazemos o direcionamento de tráfego. Você pode consultar as URLs no link abaixo:

<a href="https://learn.microsoft.com/pt-br/azure/azure-portal/azure-portal-safelist-urls?tabs=public-cloud" target="_blank">Conceder permissão às URLs do portal do Azure em seu firewall ou servidor proxy</a>

## Solução para o problema de ativação

Temos que garantir que a máquina virtual esteja configurada para usar o servidor KMS do Azure correto, para fazer isso, execute o seguinte comando:

```powershell
Invoke-Expression "$env:windir\system32\cscript.exe $env:windir\system32\slmgr.vbs /skms kms.core.windows.net:1688" 
```

O comando deve retornar o seguinte resultado:

![powershell-test-connection](/assets/img/06/04.png)

Agora o precisamos fazer é registrar novamente a máquina virtual, para isso execute o seguinte comando no prompt elevado do Windows PowerShell:
 
```powershell
Invoke-Expression "$env:windir\system32\cscript.exe $env:windir\system32\slmgr.vbs /ato" 
```

Se tudo estiver corretamente a máquina virtual será ativada pelo servidor KMS:

![powershell-test-connection](/assets/img/06/05.png)


Está lá!!!! Máquina virtual com o Windows ativado 😊 

![powershell-test-connection](/assets/img/06/06.png)

## Concluindo!

Os IPs das URLs que mencionamos acima podem ser alterados, mas se fizermos a liberação pela URL estaremos "protegidos" dessas alterações, mas de qualquer forma para os troubleshooting você já sabe o caminho a seguir! 

Lembrando pessoal que encontramos esses problemas para ativação de máquinas virtuais Windows e não temos esse problema com Linux pois a forma de licenciamento é diferente.

## Artigos relacionados

<a href="https://learn.microsoft.com/pt-br/azure/azure-portal/azure-portal-safelist-urls?tabs=public-cloud" target="_blank">Conceder permissão às URLs do portal do Azure em seu firewall ou servidor proxy</a>

<a href="https://learn.microsoft.com/pt-br/troubleshoot/azure/virtual-machines/troubleshoot-activation-problems" target="_blank">Solucionar problemas de ativação de máquina virtual do Azure Windows</a>


Espero que aproveitem o artigo e quem sabe nos encontramos em algum canto desse mundo!!!!

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
<hr>
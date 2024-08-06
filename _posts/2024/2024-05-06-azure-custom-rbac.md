---
title: 'Criar Azure Custom Roles (RBAC) para dar somente o acesso necessário'
date: 2024-05-06 10:33:00
slug: 'azure-custom-rbac'
categories: ['Azure', 'Security']
tags: ['Azure', 'Security', 'RBAC']
image:
  path: assets/img/11/11-header.webp
---

Olá pessoal! Blz?

Nesse artigo gostaria de mostrar algo que aprendemos logo no começo de nosso aprendizado em Microsoft Azure, principalmente estudando para o exame <a href="https://learn.microsoft.com/pt-br/credentials/certifications/azure-administrator/?practice-assessment-type=certification" target="_blank">AZ-104</a>, mas que raramente fazemos o uso disso quando DEVERIAMOS que são as  **Azure Custom roles** ou em portugês, **Funções personalizadas do Azure**. Eu já trabalhei em muitos projetos, de diversas empresas, isso me trouxe além de aprendizado em ver como outros Cloud Engineers trabalham, me mostrou também a falta de uso de algumas práticas que devemos realmente considerar para a segurança de nosso ambiente.

Vi que algumas empresas simplificam o acesso como um simples ***"Contributor"***, não por preguiça, mas talvez pelo desconhecimento que podemos criar acessos de forma personalizada!

O que quero dizer com o texto acima é que devemos adotar o conceito **Zero Trust (Confiança Zero)**, ou seja, dar somente a permissão necessária para a pessoa realizar o trabalho dela. Não vou entrar em detalhes sobre a Azure RBAC que são as permissões do Microsoft Azure, e sim, a personalização com um conjunto de permissões. Para mais detalhes sobre o **Azure RBAC** você pode consultar <a href="https://learn.microsoft.com/pt-br/azure/role-based-access-control/" target="_blank">nesse link.</a>

## O que são as Azure Custom Roles

Se as funções internas do Azure RBAC não atenderem às necessidades específicas de sua organização ou são permissivas demais para o que você está precisando, você poderá criar Custom Roles do Azure próprias. Assim como as funções internas, você pode atribuir Custom Roles a usuários, grupos e entidades de serviço em escopos de grupo de gerenciamento, assinatura e grupo de recursos. As Custom Roles são armazenadas em um diretório do Microsoft Entra ID e podem ser compartilhadas entre assinaturas. Cada diretório pode ter até 5 mil Custom Roles. As Custom Roles podem ser criadas usando o portal do Azure, o Azure PowerShell, a CLI do Azure ou a API REST. Aqui vamos descrever como criar Custom Roles usando o portal do Azure.

## Criando uma Azure Custom Roles

> Para criar **Custom roles** você precisará de permissões como **Proprietário** ou **Administrador de acesso do usuário.**
{: .prompt-info }

Para adicionarmos uma Azure Custom role, clique no menu **Controle de acesso (IAM)**, depois em **+ Add** e escolha a opção **Add custom role**:

![Custom RBAC](/assets/img/11/02.png)

Na primeira aba **"Basics""** temos como campos obrigatórios o nome da Custom Role e qual será a **"Baseline"**, que pode ser:

- **Clone a role:** Como na imagem abaixo você pode clonar uma role e personalizar acrescentando e/ou removendo as permissões.
- **Start from scratch:** Aqui você iria começar a criar uma Custom role do zero.
- **Start from JSON:** Nessa opção você pode fazer o upload de um arquivo JSON já existente.

![Custom RBAC](/assets/img/11/03.png)


Na aba **"Permissions"** de acordo com a baseline que você escolheu na aba anterior, você terá a listagem das permissões ou se escolheu a baseline **Start from scratch** aqui você pode incluir as permissões que deseja:

![Custom RBAC](/assets/img/11/04.png)


A seguir temos que escolher onde será aplicada a permissão, o escopo pode ser: **grupos de gerenciamento, assinatura ou grupo de recursos***, no exemplo abaixo foi aplicado o escopo da assinatura:

![Custom RBAC](/assets/img/11/05.png)

Na aba **"JSON"** você revisar como ficaria a Custom role no formato JSON e já pode clicar no botão para **Revisar e criar** que a Custom Role será criada.

![Custom RBAC](/assets/img/11/06.png)


## Como eu gosto de criar as minhas Custom Roles

Bem pessoal, no começo eu lutava um pouco contra criar uma Custom role a partir de um JSON, mas com o passar do tempo você acaba acostumando e percebe que é mais fácil.

Como no Microsoft Azure temos muitas permissões, temos que saber de onde iniciar para termos somente as permissões que precisamos, vou dar um exemplo que é muito utilizado em empresas que tem um NOC e/ou um time de monitoramento, onde pode ser necessário **Iniciar**, **Reiniciar** e/ou **Parar** uma máquina virtual, ou seja, somente isso, o usuário não pode excluir, não pode remover um disco, não pode adicionar ou modificar um disco, ele irá pode fazer somente o que a atividade dele necessita que é gerenciar o estado da máquina virtual. 

Como vocês podem ver na imagem acima, temos a saída JSON quando estamos criando um Custom Role a partir de uma outra clonada como foi feito no exemplo acima, as permissões são um exemplo como esse:

```text
                    "Microsoft.Compute/virtualMachine/*",
                    "Microsoft.Compute/disks/write",
                    "Microsoft.Compute/disks/read",
                    "Microsoft.Compute/disks/delete",
```

Então você irá me perguntar como pegar as permissões, para isso eu uso um comando powershell:

```powershell
Get-AzRoleDefinition -Name Virtual Machine Contributor | ConvertTo-Json | Out-File C:\CustomRoles\NewRole.json
```

Só que a permissão **Virtual Machine Contributor** é muito permissiva para o que propomos acima para os usuário do NOC executarem as atividades deles, então eu edito esse arquivo JSON deixando somente as permissões que desejo e atribuio o escopo para toda a assinatura:

```xml
{
    "properties": {
        "roleName": "Operador de máquinas virtuais",
        "description": "Pode ler, iniciar, reiniciar e parar máquinas virtuais",
        "assignableScopes": [
            "/subscriptions/8d7c6fb5-f932-4e13-ba06-fdf554f7527a"
        ],
        "permissions": [
           {
                "actions": [
                    "Microsoft.Compute/*/read",
                    "Microsoft.Compute/virtualMachines/start/action",
                    "Microsoft.Compute/virtualMachines/restart/action",
                    "Microsoft.Compute/virtualMachines/deallocate/action"
                ],
                "notActions": [],
                "dataActions": [],
                "notDataActions": []
            }
        ]
    }
}
```

Com o arquivo JSON ajustado para o que você precisa, podemos criar a Custom Role escolhendo a baseline **Start from JSON:**

![Custom RBAC](/assets/img/11/07.png)

## Atribuindo uma Custom Role

Depois de criada a custom rule podemos associa-la que irá receber a permissão, para atribuir a permissão é exatamente igual ao atribuir outra permissão:

![Custom RBAC](/assets/img/11/08.png)


<hr>
Para facilitar podemos digitar parte do nome que demos a Custom Role no campo de pesquisa:


![Custom RBAC](/assets/img/11/09.png)



<hr>
Após selecionar a permissão devemos atribuir a permissão, no exemplo abaixo escolhi atribuir a um usuário:


![Custom RBAC](/assets/img/11/10.png)

## Concluindo!

Espero que com esse artigo vocês comecem a pensar em restringir o acesso ao ambiente Microsoft Azure de vocês e/ou trabalham para que tenham um ambiente mais seguro ou mais controlado digamos assim. Como mencionei acima devemos dar somente as permissões que as pessoas realmente precisam ter. E personalizando essas permissões é uma boa e recomendada prática pela Microsoft.

Bom pessoal, espero que tenha gostado e que esse artigo seja util a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/pt-br/azure/role-based-access-control/tutorial-custom-role-powershell" target="_blank">Tutorial: Criar uma função personalizada do Azure usando o Azure PowerShell</a> 

<a href="https://learn.microsoft.com/pt-br/azure/role-based-access-control/custom-roles" target="_blank">Azure custom roles</a> 

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
<hr>

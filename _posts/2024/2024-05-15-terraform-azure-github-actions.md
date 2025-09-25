---
#layout: post
title: 'Implementar scripts Terraform no Microsoft Azure com GitHub Actions'
date: 2024-05-15 10:33:00
slug: 'terraform-azure-github-actions'
categories:  ['Azure', 'Terraform', 'Devops']
tags:  ['Azure', 'Terraform', 'Devops', 'GitHub Actions']
image:
  path: assets/img/12/12-header.webp
---

Olá pessoal! Blz?

Nesse artigo gostaria de demonstrar algo sobre **Implementar scripts Terraform no Microsoft Azure com GitHub Actions**, algo que me tirou um pouco da minha zona de conforto por ter conhecimento somente de Azure Devops, pode ser extremamente simples para muitos, mas para mim tive que aprender GitHub Actions em pouquissimo tempo e realmente gostei muito da ferramenta.

O que me motivou ("forçou") a isso foi o pedido de ajuda de um amigo para entregar um projeto, e para conhecer um pouco mais sobre **GitHub Actions** realizei esse curso no Udemy: <a href="https://www.udemy.com/course/github-actions-the-complete-guide" target="_blank">GitHub Actions - The Complete Guide</a>. O curso me deu a base e o conhecimento necessário para a demanda que eu precisaria executar.

## Resumo sobre GitHub Actions

GitHub Actions é uma plataforma de integração contínua e entrega contínua (CI/CD) que permite automatizar a sua compilação, testar e pipeline de implantação. GitHub Actions usa a sintaxe do YAML para definir o fluxo de trabalho (workflows). Cada fluxo de trabalho é armazenado como um arquivo YAML separado no seu repositório de código, em um diretório chamado ***.github/workflows.***

Os fluxos de trabalho são associados a um repositório GitHub. Cada fluxo de trabalho é acionado por um evento e executa uma série de trabalhos hospedados em máquinas *runners*. Cada trabalho é dividido em tarefas e cada tarefa utiliza uma ação para atingir seu objetivo. Segue abaixo o fluxo de execução do GitHub Actions:

![terraform-azure-github-actions](/assets/img/12/01.png)

## Primeiros passos

Primeiramente, precisamos ter o nosso código/scripts terraform em um repositório no GitHub. Depois, precisamos configurar algumas variáveis para conectarmos o GitHub Actions com o ambiente Microsoft Azure para podermos criar os recursos em uma assinatura.

Para conectar o GitHub Actions e o Microsoft Azure iremos usar um **Service Principal** que criamos na nossa assinatura Microsoft Azure e damos a esse service principal as devidas permissões. Para criar um service principal podemos usar o comando abaixo:

```powershell
az ad sp create-for-rbac -n SP-Terraform --role Contributor --scopes /subscriptions/00000000-0000-0000-0000-000000000000/
```

Criamos com isso um service principal com nome **SP-Terraform**, com a permissão de **Contributor (Contribuidor)** na assinatura informada no comando acima.

com a saída do comando precisaremos anotar as informações, pois precisaremos delas para configurar o GitHub Actions:

![terraform-azure-github-actions](/assets/img/12/02.png)

## Preparar o GitHub para acessar o Azure

Usaremos o Service Principal criado para nos conectarmos ao Microsoft Azure, no GitHub vamos criar algumas variáveis(segredos) com as informações do service principal. As variáveis necessárias estão listada abaixo e na frente qual a informação do Service Principal criado acima precisamos:

- ARM_CLIENT_ID: **appId**
- ARM_CLIENT_SECRET: **password**
- ARM_SUBSCRIPTION_ID: **ID da subscription que usamos na criação do service principal "00000000-0000-0000-0000-000000000000"**
- ARM_TENANT_ID: **tenant**

Para criar as variáveis seguimos o seguinte caminho:

![terraform-azure-github-actions](/assets/img/12/03.png)
<hr>

![terraform-azure-github-actions](/assets/img/12/04.png)

<hr>

Digite o nome da variável e o Valor:

![terraform-azure-github-actions](/assets/img/12/05.png)

<hr> 

> Lembrando que após adicionar a variável você pode apenas alterar o valor mas não ver qual o valor está na variável.
{: .prompt-info }

 ## Criando a pipeline do GitHub Actions
 
 Para criarmos uma pipeline para deploy da infraestrutura Terraform seguimos o seguinte caminho: **Actions => New Workflow => set up a workflow yourself**.
 
![terraform-azure-github-actions](/assets/img/12/06.png)

![terraform-azure-github-actions](/assets/img/12/07.png)

<br>
 
 Abrirá um editor para inserirmos o script YAML com os ***jobs, steps e tasks*** que essa pipeline irá executar:

![terraform-azure-github-actions](/assets/img/12/08.png)

<br>

## Script YAML para deploy de código Terraform

Abaixo segue um exemplo de script yaml para deploy de recursos no Microsoft Azure com os scripts Terraform que temos dentro do repositório, o gatilho para executar a pipeline é o **push para a branch main** (linha 3) como temos no trecho abaixo:

> O gatilho abaixo é somente um exemplo, você precisa adaptar da forma que mais lhe interessa, seja manualmente, por um merge ou por um Pull Request.
{: .prompt-warning }

```yaml
{% raw %}
name: 'Deploy Terraform on Microsoft Azure'
# Gatilho para executar a pipeline
on:
  push:
    branches:
    - main

jobs:
  terraform:
    name: 'Terraform Job'
    runs-on: ubuntu-latest
    environment: production
    env:
      working-directory: ${{ github.workspace }}
      ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
      
    defaults:
      run:
        shell: bash
   
    steps:
    - name: Checkout Script Terraform da branch
      uses: actions/checkout@v3
      
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_wrapper: false 

    - name: Terraform Init
      working-directory: ${{ env.working-directory }}
      run: terraform init

    - name: Terraform Plan
      working-directory: ${{ env.working-directory }}
      run: terraform plan 
      
    - name: Terraform Apply
      working-directory: ${{ env.working-directory }}
      run: terraform apply -auto-approve
{% endraw %}
```

<br>
Após o término da execução da pipeline, temos um overview da execução da pipeline como tempo de duração, jobs que foram executados e o status:

![terraform-azure-github-actions](/assets/img/12/09.png)

<br>

## Concluindo!

Apesar que no começo achava que era um "bicho papão", acho importante conhecermos alguma outra ferramenta que faz a mesma coisa que a ferrmenta que temos confiança, no meu caso o Azure Devops, mas o GitHub Actions é uma ferramenta muito interessante e que vale algumas horas de estudos, como agora temos as certificações GitHub com certeza irei me dedicar a esses exames.

Esse foi um exemplo bem simples mas pode te dar um norte em sua primeira utilização!!

Bom pessoal, espero que tenha gostado e que esse artigo seja util a vocês!

## Artigos relacionados

<a href="https://github.com/Azure-Samples/terraform-github-actions" target="_blank">GitHub Actions Workflows for Terraform</a> 

<a href="https://developer.hashicorp.com/terraform/tutorials/automation/github-actions" target="_blank">Automate Terraform with GitHub Actions</a> 

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
<hr>
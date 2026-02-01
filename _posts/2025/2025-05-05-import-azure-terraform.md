---
title: "Importar recursos Microsoft Azure e gerando código Terraform com aztfexport"
date: 2025-05-05 01:00:00
categories: [Devops, Terraform]
tags: [devops, terraform, azure]
slug: 'import-azure-terraform'
image:
  path: /assets/img/37/37-header.webp
---

Olá pessoal! Blz?

Uma questão comum quando queremos/desejamos automatizar o deploy de recursos em cloud usando Terraform em ambientes existentes é: **"O que faremos com os recursos existentes para podermos gerenciá-los através do Terraform?"**

Para essa questão temos no Terraform a opção de importar os recursos com o comando `terraform import`, mas isso não gera o código Terraform para esses recursos e somente iria importá-los para o arquivo de estado. Como isso seria uma tarefa manual e não atende totalmente por não gerar o código, devemos explorar outras opções e uma ótima ferramenta e que abordaremos nesse artigo é a **aztfexport** da Microsoft, uma ferramenta que ajuda a gerenciar facilmente seus recursos existentes do Azure no Terraform.

## O que é o aztfexport?

O **aztfexport** é uma ferramenta open source criada pela Microsoft para importar recursos existentes do Azure sob o gerenciamento do Terraform, ou seja, você pode importar seus recursos já criados no Azure dentro de um arquivo de estado e ainda melhor, você pode gerar o código Terraform desses recursos para caso precise alterar algo depois.

Eu acho estranho que a ferramenta tenha no nome ***export***, mas seu principal uso é para importar os recursos para serem gerenciados pelo Terraform, mas pode ser no sentido de exportar o código Terraform dos recursos e/ou exportar do portal para ser gerenciado pelo Terraform. 😕

![import-azure-terraform](/assets/img/37/01.png){: .shadow .rounded-10}

## Limitações do aztfexport

A ferramenta é fantástica, mas possui algumas limitações que podem ser contornadas, vale lembrar que ela é uma ferramenta para lhe ajudar e pode ser necessário algum ajuste manual para deixar o seu ambiente Terraform de acordo com suas necessidades. Algumas limitações que devemos considerar:

- **Infraestrutura fora do escopo de recursos:** os recursos necessários para a configuração podem existir fora do escopo especificado. 
- **Recursos definidos pela propriedade:** determinados recursos no Azure podem ser definidos como uma propriedade em um recurso Terraform pai ou um recurso Terraform individual. Um exemplo é uma sub-rede que é definido como um recurso individual.
- **Dependências explícitas:** no momento, o aztfexport pode declarar apenas dependências explícitas. Você deve conhecer o mapeamento das relações entre recursos para refatorar o código para incluir quaisquer dependências implícitas necessárias.
- **Valores sensíveis:** o aztfexport atualmente gera cadeias de caracteres codificadas. Como prática recomendada, você deve refatorar esses valores para variáveis. Além disso, quando você usa o sinalizador --full-properties para expor todas as propriedades, algumas informações confidenciais (como segredos) podem ser vistas na configuração gerada. 

## Pré requisitos para usar o aztfexport

Para usarmos o aztfexport temos alguns requisitos que devem estar presente onde você irá executar:

- Uma conta e assinatura do Azure.
- Terraform com versão >= v0.12 configurado na variável de ambiente ***$PATH***.
- O Azure CLI instalado.
- Perfil do Azure configurado na CLI do Azure para ler recursos em sua assinatura do Azure. (az login)

## Instalação

A instalação do **aztfexport** é simples e você pode escolher a release e a plataforma diretamente <a href="https://github.com/Azure/aztfexport/releases" target="_blank">aqui na página do projeto no github.</a> Com a release escolhida você pode seguir com a instalação padrão de cada plataforma.

Mas se você prefere a instalação através de gerenciadores de pacotes pode usar alguns desses:

#### Windows

```bash
winget install aztfexport
```

#### dnf (Linux)

Versão suportada: **RHEL 8 ou 9 (amd64, arm64)**

```bash
#Import the Microsoft repository key:

rpm --import https://packages.microsoft.com/keys/microsoft.asc

#Add packages-microsoft-com-prod repository:

ver=8 # or 9
dnf install -y https://packages.microsoft.com/config/rhel/${ver}/packages-microsoft-prod.rpm

#Install:

dnf install aztfexport
```

#### apt (Linux)

Versão suportada: **Ubuntu 20.04 ou 22.04 (amd64, arm64)**

```bash
#Import the Microsoft repository key:

curl -sSL https://packages.microsoft.com/keys/microsoft.asc > /etc/apt/trusted.gpg.d/microsoft.asc

#Add packages-microsoft-com-prod repository:

ver=20.04 # or 22.04
apt-add-repository https://packages.microsoft.com/ubuntu/${ver}/prod

#Install:

apt-get install aztfexport
```

## Como usar o ***aztfexport***

O uso de forma mais simples se resume no comando abaixo, a maneira mais fácil de ver todas as opções que melhor lhe atende é executar o comando `aztfexport --help`, é a página de ajuda da ferramenta e mostra como usar as opções.

```
aztfexport [command] [option] <scope>
```

Existem 3 (três) comandos que você pode escolher de acordo com o que você deseja importar:

| Tarefa | Exemplo |
|-|-|
| Importar um único recurso | aztfexport resource [option] &lt;resource id> |
| Importar um resource group | aztfexport resource-group [option] &lt;resource group name> |
| Importar usando uma query. | aztfexport query [option] &lt;ARG where predicate> |

> Você deve estar conectado a assinatura no shell que estiver usando, pode ser usado o `az login` para se conectar ao Microsoft Azure.
{: .prompt-info } 

Vamos começar com um exemplo simples, iremos gerar o código Terraform e o arquivo de estado para um resource group chamado `rg-network`:

```bash 
aztfexport resource-group 'rg-network'
```
![import-azure-terraform](/assets/img/37/02.png){: .shadow .rounded-10}

Como podemos ver na imagem abaixo dentro desse resource group temos **52 recursos**, podemos de forma interativa ir navegando entre os recursos para ver erros ou recomendações, após revisar podemos pressionar a tecla **w** para importar os recursos:

![import-azure-terraform](/assets/img/37/03.png){: .shadow .rounded-10}

Com isso é iniciando a criação dos arquivos Terraform na pasta atual, os arquivos gerados incluem:

- Arquivo de estado local (terraform.tfstate)
- Arquivos de código Terraform (provider.tf, terraform.tf e main.tf)
- Arquivo JSON com um mapa de todos os recursos

```bash
$ tree
.
├── aztfexportResourceMapping.json
├── main.tf
├── provider.tf
├── terraform.tf
└── terraform.tfstate
```

No arquivo **main.tf** é gerado o código Terraform de todos os recursos que havia dentro do resource group que escolhemos, o que eu acho bem legal que ele usa o `depends_on` para tratar as dependências:

![import-azure-terraform](/assets/img/37/04.png){: .shadow .rounded-10}

> Temos 2 (duas) opções importantes que são **--overwrite, -f** e **--append**, o primeiro sobrescreve tudo que já existe no diretório e o **append** ele importa os recursos para um arquivo de estado existente.   
{: .prompt-tip } 

## Alguns exemplos de uso para o dia a dia

Vou colocar algumas opções de parâmetros que pode ser útil no dia a dia, mas como falei acima a ferramenta tem muitas opçoes e é melhor consultá-las com `aztfexport --help`.

### Gerar somente os arquivos .tf

```bash 
# Gera somente os arquivos .tf e não gera o arquivo terraform.tfstate
aztfexport resource-group --hcl-only 'rg-network'
```

### Incluir as permissões **role assignment**

```bash 
aztfexport rg  --include-role-assignment 'rg-network'
```

> Podemos usar somente a abreviação **rg** para resource-group ou **res** para resource
{: .prompt-tip } 

### Executar o comando de forma **NÃO** interativa

```bash 
# Podemos usar também a abreviação -n
aztfexport resource-group --non-interactive 'rg-network'
```

### Gerar o arquivo **import.tf**

Se deve gerar o **import.tf** que contém os blocos "import" para a importação através do Terraform plan

```bash 
aztfexport rg  --generate-import-block  'rg-network'
```

![import-azure-terraform](/assets/img/37/05.png){: .shadow .rounded-10}

### Usando queries para filtrar recursos

```bash 
# Filtra o resource group 'rg_network' e somente os recursos que contém 'Microsoft.Network'
aztfexport query -n "resourceGroup =~ 'rg-network' and type contains 'Microsoft.Network'"
```

### Filtrar recursos com uma TAG específica

```bash 
# Filtra os recursos que possuem a TAG environment:PRD 
aztfexport query -n -r --include-resource-group "tags['environment'] == 'PRD'"
```

### Exportar para um arquivo de estado remoto no Azure

Para gerar um arquivo de estado remoto no Azure em uma storage account devemos usar o comando abaixo:

```shell
aztfexport query --backend-type=azurerm \
            --backend-config=subscription_id=0000-0000-000-0000-0000-000 \
            --backend-config=resource_group_name=rg-terraform \
            --backend-config=storage_account_name=storageaccountname \
            --backend-config=container_name=terraform \
            --backend-config=key=terraform.tfstate -n "resourceGroup =~ 'rg-network'" 
```

## Importar todos os resource groups da Assinatura

No exemplo abaixo eu fiz um script simples em Powershell para pegar todos os resource groups da assinatura e gerar apenas o código Terraform dos recursos, os recursos ficarão separados por pastas como no exemplo abaixo:

![import-azure-terraform](/assets/img/37/06.png){: .shadow .rounded-10}

Segue o script para gerar os códigos Terraform dos recursos:

```powershell
$rgs = get-azresourcegroup

foreach ($rg in $rgs) {

    $rgName = $rg.ResourceGroupName

    if ((-not $rgName.StartsWith("DefaultResourceGroup")) -and (-not $rgName.StartsWith("NetworkWatcherRG"))) {
     
     # Cria um diretorio com o nome do resource group 
     $dir = "C:\Temp\terraform\" + $rg.ResourceGroupName
     New-Item -Path $dir -ItemType "Directory"

     aztfexport rg -n --include-role-assignment --hcl-only --output-dir $dir $rg.ResourceGroupName 

    }
}
```

> Podemos usar o parâmetro **--output-dir** para informar o caminho do diretório que desejamos que seja salvo os arquivos.
{: .prompt-tip } 

## Concluindo!

Usar a ferramenta **aztfexport** é uma escolha estratégica para equipes que buscam maior controle, rastreabilidade e padronização da infraestrutura em Azure. Ela permite extrair automaticamente recursos existentes no Azure e convertê-los em código Terraform, economizando tempo e reduzindo erros humanos no processo de criação de arquivos de configuração. Além disso, facilita a adoção de boas práticas DevOps, como versionamento de infraestrutura, revisões em pull requests e integração com pipelines CI/CD. Em resumo, o aztfexport acelera a transição para IaC com menos esforço e mais segurança, promovendo agilidade, governança e consistência na gestão da nuvem.

Bom pessoal, eu tenho usado isso em alguns ambientes e acredito que possa ser bem útil a vocês!

## Artigos relacionados

<a href="https://github.com/Azure/aztfexport" target="_blank">Projeto do aztfexport no GitHub</a>

<a href="https://learn.microsoft.com/en-us/azure/developer/terraform/azure-export-for-terraform/export-terraform-overview" target="_blank">Overview of Azure Export for Terraform</a>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
---
title: 'HashiCorp Terraform Certification 003: como me preparei para esse exame'
date: 2024-04-01 10:33:00
slug: 'terraform-certification'
categories: ['Certificação', 'Terraform']
tags: ['Certificação', 'Terraform']
image:
  path: assets/img/08/08-header.webp
---

Olá pessoal! Blz?

Gostaria de compartilhar com vocês como foi minha preparação para a certificação **HashiCorp Terrafrom 003.** Eu já possuia essa certificação na versão HashiCorp Terrafrom 002 e como essa renovação é obtida através de um novo exame tive que dedicar um tempo aos estudos e vou compartilhar como me preparei.

> Microsoft me deixou mal acostumado com o modelo de renovação sem precisar pagar um novo exame!!!! 😆😆

![powershell-test-connection](/assets/img/08/01.png){: width="300" height="300" }

## Sobre o exame

Eu não senti muita diferença entre as versões 002 e 003, mas deixarei abaixo uma tabela para as pessoas que irão renovar a certificação saiba o que foi alterado. A prova continua com um grau de dificuldade onde realmente a prática faz a diferença, digo isso pois alguns exames somente estudando a teoria já é suficiente, mas nesse exame o ***uso e prática de vários laboratórios e testes serão recompensados, pois tem certas questões que somente a "mão na massa" te dará a resposta.***

No meu exame caiu uma questão para digitar o comando em uma caixa de texto necessário para realizar o que pediam no enunciado, nessa questão eu fiquei desconfortável pois o enunciado não foi claro o que eles esperavam, se era algo mais complexo ou sucinto, a questão era sobre criar uma dependência manualmente, eu sabia que deveria usar o ***depends_on*** mas não sei se era só digitar isso ou precisava colocar ***depends_on = []***, enfim, estejam preparados para questões assim.

Os snippet de código usado no exame a maioria, se não me falha a memória: todos, são voltados para AWS, mesmo tento maior conforto com Microsoft Azure isso não atrapalha pois você precisa responder algo relacionado ao uso de Terraform e não sobre o provider, então eh de boa!!!

Pode cair uma questão com esse snippet e a questão ser relacionada ao uso do ***data*** na linha 2, por exemplo:

![powershell-test-connection](/assets/img/08/03.png)

> Como falei, não precisa se preocupar em não saber o Cloud Provider, se preocupe em saber sobre a linguagem HCL (Terraform).
{: .prompt-tip }

#### Abaixo algumas características sobre o exame:

| Chave | Valor |
|---|---|
| Tipo de avaliação  | Multipla escolha  |
| Formato  | Online monitorado  |
| Duração  | 1 hora  |
| Questões | 57  |
| Preço  | $70.50 USD* Taxas locais podem ser aplicadas |
| Idioma | Inglês  |


O que é cobrado no exame e mais detalhes você pode consultar no site oficial do exame: <a href="https://www.hashicorp.com/certification/terraform-associate" target="_blank">HashiCorp Infrastructure Automation Certification</a>

O ponto negativo do exame é que só é possível realizar através da **PSI**, depois que você acostuma a realizar exames com a **Pearson Vue** você acaba se irritando com essa plataforma de exames...😒

Foi necessário ficar rodando o laptop para mostrar mesa, quarto, debaixo da mesa, dessa vez implicaram com o roteador de internet que estava próximo e acreditem, até as orelhas me pediram para ver se estaria usando earphones, sorte que as orelhas estavam limpas 😆😆.

No mais a plataforma do exame é estável e tranquila!

## Diferença entre as versões do exame

Abaixo a relação do que mudou da versão 002 para 003, poucas diferenças:

| Item | Objetivos | Terraform certification 003  |
|---|---|---|
| **3e** | To ~~Explain when to use and not use provisioners and when to use local-exec or remote-exec~~ | Removed |
| **4** | Use Terraform outside of the core workflow | **terraform taint** removed and mentioned a lot the use of ***terraform apply -replace="resource"***, other topics reorganized |
| **6b** | Initialize a Terraform working directory (**terraform init**)  | Includes questions about **terraform.lock.hcl** |
| **7**  | Implement and maintain state |  Cloud integration authentication and cloud backends added |
| **8a** | Demonstrate the use of variables and outputs | Covers sensitive variables and outputs’ relationship to exposure on the CLI |
| **8g** | To ~~Configure~~ resources using a **dynamic block**  | Use cases for **dynamic block** is still tested in objective 8  |
| **9** | Understand Terraform Cloud capabilities | Restructured to accommodate the current and future state of Terraform Cloud |

No exame que fiz em 2022 na versão HashiCorp Terrafrom 002 não cairam muitas questões sobre Terraform cloud, dados sensíveis, remote state e outputs, mas nessa versão 003 teve muitas questões sobre esses assuntos! Então é mais uma dica 😉.

## Como me preparei para o exame

Para me preparar para o exame realizei o curso que o meu amigo <a href="https://www.linkedin.com/in/antoniocarlosjr/" target="_blank">Antonio Carlos da Silva Junior </a> ministrou na <a href="https://portal.tftecprime.com.br/m/c/terrafom-associate-1694628491755" target="_blank">TFTEC CLOUD - Curso de Terraform</a> e já está atualizado para a versão mais nova do exame HashiCorp Terrafrom 003.

Também usei o mesmo curso na Udemy que estudei para o exame que fiz em 2022 (HashiCorp Terrafrom  002) e o curso já está atualizado para a versão HashiCorp Terrafrom 003 do exame, <a href="https://www.udemy.com/course/terraform-beginner-to-advanced/" target="_blank">HashiCorp Certified: Terraform Associate 2024 </a> ministrado pelo <a href="https://www.linkedin.com/in/zealvora/" target="_blank">Zeal Vora</a>.

Para testar/validar o conhecimento e ponto de melhoria usei o simulado da Udemy <a href="https://www.udemy.com/course/terraform-associate-practice-exam/" target="_blank">HashiCorp Certified: Terraform Associate Practice Exam 2024.</a>

Recomendo muito o uso de simulados para que você veja os pontos em que está errando e acertando, esse simulado citado acima, te da a explicação para as respostas e com isso você pode voltar nos cursos e refazer e/ou validar o porque errou a questão.

## Concluindo!

Pessoal gostaria de terminar repetindo o que disse acima, esse é um exame que você realmente precisa se dedicar muito a prática, errar muito, arrancar os cabelos tentando resolver problemas, realizar diversos laboratórios e o mais importante aprender com os erros.

Essa não é uma prova chata e massante! Eu gosto de terraform e sempre aprendo mais no dia a dia, então horas de estudos são gratificantes.

Bom pessoal, espero que tenha gostado e que esse artigo seja util a vocês!

## Artigos relacionados

<a href="https://www.hashicorp.com/certification/terraform-associate" target="_blank">HashiCorp Infrastructure Automation Certification</a> 

<hr>
Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!

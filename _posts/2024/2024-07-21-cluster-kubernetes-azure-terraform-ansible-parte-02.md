---
#layout: post
title: 'Cluster Kubernetes com Terraform e Ansible - parte 2' 
date: 2024-07-21 00:01:00
categories: ['Azure', 'Devops', 'Kubernetes', 'Ansible']
tags: ['Azure', 'Devops', 'Kubernetes', 'Ansible']
slug: 'cluster-kubernetes-azure-terraform-ansible-parte-02'
image:
  path: assets/img/17/17-header.png
---

Olá Pessoal! Blz?

Dando continuidade ao artigo anterior onde criamos a infraestrutura do nosso cluster kubernetes no Microsoft Azure usando o terraform, vamos nesse artigo usar o ansible para instalar e configurar os pacotes necessários para o nosso cluster kubernetes.

Lembrando que o objetivo é a criação de um ambiente de estudos para o exame <a href="https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/" target="_blank">CKA (Certified Kubernetes Administrator)</a>, então, vocês podem achar que está faltando algo relacionado a melhores práticas, segurança ou outro detalhe que como ainda estou estudando possa ter passado despercebido ou eu não saber mesmo (que é o mais provável) 😆😆 !!!

Nesse artigo não vou detalhar a instalação do Ansible, mas deixarei um link para que vocês possam instalar: <a href="https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html" target="_blank">Instalar o ansible</a>, voce pode instalar em seu computador e executar remotamente as playbooks.

Os scripts do Ansible eu preferi dividí-los para que o entendimento ficasse melhor, e além dos scripts precisamos do arquivo de hosts. Você pode baixar os arquivos no meu **GitHub:** <a href="https://github.com/lharantes/cluster-k8s-terraform-ansible" target="_blank">cluster-k8s-terraform-ansible</a>.

## Primeiros passos

Primeiramente, vamos criar uma pasta e colocar nessa pasta todos os arquivos que precisamos para executar os scripts, o conteúdo da pasta é o seguinte:

```yaml
❯ ls -l
total 64
-rwxr--r--@ 1 luiz  staff   198  9 Jul 10:48 hosts
-rw-------  1 luiz  staff  3247 15 Jul 19:56 linuxkey.pem
-rw-r--r--@ 1 luiz  staff   121  9 Jul 14:06 main.yml
-rw-r--r--@ 1 luiz  staff  4134  9 Jul 13:58 requisitos.yml
-rw-r--r--@ 1 luiz  staff  1677  9 Jul 14:13 master.yml
-rw-r--r--@ 1 luiz  staff   555  9 Jul 13:45 workers.yml
```

Os arquivos acima tem as seguintes funções:

- **hosts:** arquivo com a lista de todos os servidores onde iremos executar a instalação e configuração. Com o output do Terraform que executamos anteriormente temos a seguinte saida:

![azure-ansible](/assets/img/17/01.png)

No arquivo de hosts deixei da seguinte forma:

```yaml
[master]
vm-master.eastus2.cloudapp.azure.com

[workers]
vm-worker01.eastus2.cloudapp.azure.com
vm-worker02.eastus2.cloudapp.azure.com

[all:vars]
user_azure=azadmin
```

- **linuxkey.pem:** nossa chave privada SSH para conectar nos servidores

- **main.yml:** arquivo onde iremos importar os playbooks Ansible e será a playbook que iremos executar

- **requisitos.yml:** playbook com a instalação e configuração dos requisitos necessários para todos os servidores do cluster

- **master.yml:** configuração do nó master (Control Plane)

- **worker.yml:** inclusão dos nós workers ao cluster


Para ver se está tudo ok e se, principalmente, temos acesso as máquinas virtuais, podemos executar um "ping" para testar a conectividade:

Para isso usando o comando:

```yaml
ansible -i hosts all -m ping
```

![azure-ansible](/assets/img/17/02.png)

Com o acesso  ok podemos seguir com as demais etapas e executar as playbooks do Ansible. 

## Arquivo main.yml

Esse arquivo é somente para importar as playbook do Ansible para não ter que executar manualmente 1 a 1 os arquivos:

```yaml
❯ cat main.yml

- import_playbook: requisitos.yml
- import_playbook: master.yml
- import_playbook: workers.yml

```

Esse é o arquivo que iremos executar para "chamar" as outras playbooks, vocês podem fazer isso com o comando:

```yaml
ansible-playbook -i hosts all main.yml

```

A seguir irei deixar as playbooks que são importadas pela playbook main.yml.

## Arquivo requisitos.yml

Os servidores para fazerem parte de um cluster kubernetes possuem alguns requisitos e no playbook abaixo iremos instalá-los, em cada task tem o nome que diz o que a determinada task está fazendo para ajudar a compreender melhor a playbook:

```yaml 
{% raw %}
- name: Preparar servidores para o ambiente Kubernetes 
  hosts: all
  become: yes
  tasks:
    - name: Updates
      apt:
        update_cache: yes

    - name: Instalar pacotes necessarios 
      apt:
        name: '{{ item }}'
        state: present
      loop:
        - curl
        - apt-transport-https
        - ca-certificates

    - name: Desabilitar SWAP
      shell: |
        swapoff -a

    - name: Desabilitar SWAP no arquivo fstab
      replace:
        path: /etc/fstab
        regexp: '^([^#].*?\sswap\s+sw\s+.*)$'
        replace: '# \1'

    - name: Criar um arquivo vazio para o modulo containerd
      copy:
        content: ""
        dest: /etc/modules-load.d/containerd.conf
        force: no

    - name: Configurar modulo para o containerd
      blockinfile:
        path: /etc/modules-load.d/containerd.conf
        block: |
          overlay
          br_netfilter

    - name: Criar um arquivo vazio para o K8S sysctl parameters
      copy:
        content: ""
        dest: /etc/sysctl.d/99-kubernetes-cri.conf
        force: no

    - name: Configurar parametros sysctl parameters para kubernetes
      lineinfile:
        path: /etc/sysctl.d/99-kubernetes-cri.conf
        line: "{{ item }}"
      with_items:
        - "net.bridge.bridge-nf-call-iptables  = 1"
        - "net.ipv4.ip_forward                 = 1"
        - "net.bridge.bridge-nf-call-ip6tables = 1"

    - name: Aplicar parametros sysctl 
      command: sysctl --system

    - name: Adicionar chave Docker apt-key
      get_url:
        url: https://download.docker.com/linux/ubuntu/gpg
        dest: /etc/apt/keyrings/docker-apt-keyring.asc
        mode: "0644"
        force: true

    - name: Adicionar repositorio Docker's APT
      apt_repository:
        repo: "deb [arch={{ 'amd64' if ansible_architecture == 'x86_64' else 'arm64' }} signed-by=/etc/apt/keyrings/docker-apt-keyring.asc] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
        state: present
        update_cache: yes

    - name: Adicionar chave Kubernetes apt-key
      get_url:
        url: https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key
        dest: /etc/apt/keyrings/kubernetes-apt-keyring.asc
        mode: "0644"
        force: true

    - name: Adicionar repositorio Kubernetes APT
      apt_repository:
        repo: "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.asc] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /"
        state: present
        update_cache: yes

    - name: Instalar containerd
      apt:
        name: containerd.io
        state: present

    - name: Criar diretorio containerd 
      file:
        path: /etc/containerd
        state: directory

    - name: Adicionar configuracao containerd
      shell: /usr/bin/containerd config default > /etc/containerd/config.toml

    - name: Configurar Systemd cgroup driver para containerd
      lineinfile:
        path: /etc/containerd/config.toml
        regexp: "            SystemdCgroup = false"
        line: "            SystemdCgroup = true"

    - name: Habilitar o servico containerd e iniciar o servico
      systemd:
        name: containerd
        state: restarted
        enabled: yes
        daemon-reload: yes

    - name: Instalar Kubelet na versao 1.29.*
      apt:
        name: kubelet=1.29.*
        state: present
        update_cache: true

    - name: Instalar Kubeadm na versao 1.29.* 
      apt:
        name: kubeadm=1.29.*
        state: present

    - name: Habilitar o servico Kubelet 
      service:
        name: kubelet
        enabled: yes

    - name: Carregar o kernel modulo br_netfilter
      modprobe:
        name: br_netfilter
        state: present

    - name: Definir bridge-nf-call-iptables
      sysctl:
        name: net.bridge.bridge-nf-call-iptables
        value: 1

    - name: Definir ip_forward
      sysctl:
        name: net.ipv4.ip_forward
        value: 1

    - name: Reboot os servidores
      reboot:

- hosts: master
  become: yes
  tasks:
    - name: Instalar Kubectl na versao 1.29.* 
      apt:
        name: kubectl=1.29.*
        state: present
        force: yes
{% endraw %}
```

## Arquivo master.yml

A playbook **master.yml** configura o servidor escolhido para ser o Master ou Control Plane do cluster kubernetes, a variavel ***"{{ user_azure }}"*** foi definida no arquivo de inventário e é o usuário que criamos para as máquinas virtuais:

```yaml
{% raw %}
- name: Configurar o servidor control plane
  hosts: master
  become: yes
  tasks:
    - name: Criar um arquivo vazio para a configuracao do Kubeadm
      copy:
        content: ""
        dest: /etc/kubernetes/kubeadm-config.yaml
        force: no

    - name: Configurar container runtime
      blockinfile:
        path: /etc/kubernetes/kubeadm-config.yaml
        block: |
          kind: ClusterConfiguration
          apiVersion: kubeadm.k8s.io/v1beta3
          networking:
            podSubnet: "10.244.0.0/16"
          ---
          kind: KubeletConfiguration
          apiVersion: kubelet.config.k8s.io/v1beta1
          runtimeRequestTimeout: "15m"
          cgroupDriver: "systemd"
          systemReserved:
            cpu: 100m
            memory: 350M
          kubeReserved:
            cpu: 100m
            memory: 50M
          enforceNodeAllocatable:
          - pods

    - name: Inicializar o cluster
      shell: kubeadm init --config /etc/kubernetes/kubeadm-config.yaml 

    - name: Criar diretorio .kube na pasta home do usuario {{ user_azure }}
      become: yes
      become_user: "{{ user_azure }}"
      file:
        path: /home/{{ user_azure }}/.kube
        state: directory
        mode: 0755

    - name: Copiar admin.conf para kube config do usuario {{ user_azure }}
      copy:
        src: /etc/kubernetes/admin.conf
        dest: /home/{{ user_azure }}/.kube/config
        remote_src: yes
        owner: "{{ user_azure }}"

    - name: Instalar Pod Network
      become: yes
      become_user: "{{ user_azure }}"
      shell: kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml 
{% endraw %}
```

## Arquivo worker.yml

No arquivo **worker.yml** fazemos o **join no cluster kubernetes** dos 2 servidores definidos como workers:

```yaml
{% raw %}
name: Criar o comando de Join no Master Node
  become: yes
  hosts: master
  tasks:
    - name: Executar o comando para gerar o token
      shell: kubeadm token create --print-join-command
      register: join_command_raw

    - name: Criar um Fact do comando de Join
      set_fact:
        join_command: "{{ join_command_raw.stdout_lines[0] }}"
    
- name: Incluir os servidores Workers no cluster
  hosts: workers
  become: yes  
  tasks:
    - name: Incluindo o servidor no cluster
      shell: "{{ hostvars[groups['master'][0]]['join_command'] }}"
{% endraw %}
```

## Resultado da execução dos scripts

Após executar o comando **ansible-playbook** mencionado acima, esperamos ver o resultado abaixo onde todas as tasks foram executadas com sucesso.

![azure-terraform](/assets/img/17/03.png)

Para conectar a máquina virtual master uso o seguinte comando SSH passando a chave privada:

```yaml
ssh -i linuxkey.pem azadmin@vm-master.eastus2.cloudapp.azure.com
```

Dentro da máquina virtual **Master** podemos consultar os servidores que fazem parte do cluster:

```yaml
kubectl get nodes -o wide
```

![azure-terraform](/assets/img/17/04.png)

E nosso ambiente de estudos, um cluster kubernetes está pronto e todo configurado!!!!

## Concluindo!

Bom pessoal, nessa segunda parte terminamos a configuração do nosso cluster kubernetes, e como falei criei isso para ter um ambiente de estudos sempre que eu precise e que eu faça isso de forma "automatizada", eu coloco os scripts para rodar e vou tomar um café e quando volto meu ambiente está pronto!
<hr>

Compartilhe o artigo com seus amigos clicando nos ícones abaixo!!!
<hr>
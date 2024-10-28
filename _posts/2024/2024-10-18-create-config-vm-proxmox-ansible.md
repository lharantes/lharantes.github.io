---
#layout: post
title: 'Criar e configurar uma máquina virtual no Proxmox com Ansible' 
date: 2024-10-17 01:33:00
categories: [HomeLab, Proxmox]
tags: [homelab, proxmox, ansible]
slug: 'create-config-vm-proxmox-ansible'
image:
  path: assets/img/26/26-header.webp
---

Olá pessoal! Blz?

Nesse artigo eu quero trazer a vocês como eu faço para criar e configurar uma máquina virtual no meu servidor Proxmox em meu HomeLab usando o Ansible, vou deixar também uma task que uso para enviar uma mensagem no Telegram depois que a máquina virtual está pronta para uso. No artigo passado eu mostrei a vocês <a href="https://arantes.net.br/posts/create-template-proxmox/" target="_blank">como criar uma VM "template" Linux para usar no Proxmox</a>, e foi mostrado no artigo que para criar a máquina virtual e só clicar com o botão direito no template e escolher a opção ***"Clonar"***.

Ok certo!!!Mas então por que eu tenho usando o Ansible para isso???? Bem a resposta é: para além de criar, usar o Ansible para deixar essa máquina virtual configurada e pronta para o uso, instalando alguns pacotes básicos.

> Eu não deixo isso já pronto na imagem que uso de template pois eu posso querer usar o template para um propósito diferente.
{: .prompt-info }

## Requisitos para uso do Ansible e Proxmox

Para usarmos o Ansible e Proxmox em conjunto precisamos de alguns itens, alguns deles mostrarei como criar e outros deixarei o link:

- **API Token**: para nos autenticarmos no Proxmox

- **Template**: para realizar o clone, você pode criar seu template seguindo <a href="https://arantes.net.br/posts/create-template-proxmox/" target="_blank">esse artigo</a>

- **Arquivo de hosts**: arquivo com pelo menos o host do Proxmox

## Criar uma API Token para autenticação

Criaremos um usuário somente para uso com o Ansible, para criar um usuário na interface web do Proxmox devemos ir em **Datacenter -> Permissions -> Users -> Add**, 

![create-config-vm-proxmox-ansible](/assets/img/26/01.png){: .shadow .rounded-10}

Na tela de cadastro de usuários devemos preencher pelo menos o campo **User Name**, mas eu gosto de colocar um comentário para identificar o propósito daquele usuário:

![create-config-vm-proxmox-ansible](/assets/img/26/02.png){: .shadow .rounded-20}

Para gerar um API Token no Proxmox vá em **Datacenter -> Permissions -> API Token -> Add**.

![create-config-vm-proxmox-ansible](/assets/img/26/04.png){: .shadow .rounded-20}

Após clicar em **"Add"** o token será exibido: 

![create-config-vm-proxmox-ansible](/assets/img/26/05.png){: .shadow .rounded-20}

> Copie o token e guarde em algum lugar pois não será exibido novamente.
{: .prompt-info }

Em seguida, atribua permissões ao usuário ansible e ao token associado. Requer pelo menos essas permissões.

![create-config-vm-proxmox-ansible](/assets/img/26/03.png){: .shadow .rounded-100}

## Estrutura de arquivos e pastas de como eu uso

> Para nao ficar extenso o artigo eu vou colocar os arquivos principais, mas para ter todos os arquivos vocês podem acessar o repositório no GitHub: <a href="https://github.com/lharantes/arquivos-blog/tree/main/create-config-vm-proxmox-ansible" target="_blank">create-config-vm-proxmox-ansible</a> 
{: .prompt-info }

Tenho uma pasta com o nome **homelab-ansible** onde eu mantenho as roles que uso em meu ambiente HomeLab, ainda está bem no começo mas quero continuar estudando e aplicando no meu ambiente. A estrutura de pastas está da seguinte maneira: ***uma pasta para as roles***, ***o arquivo de hosts***, ***o arquivo de configuração do Ansible (ansible.cfg)*** e o arquivo ***main.yml*** que eu uso para chamar as roles que eu quero executar, a estrutura de pastas e arquivos ficam da seguinte maneira:

```
📦homelab-ansible
 ┣ 📂roles
 ┃ ┣ 📂config-vm-linux
 ┃ ┃ ┣ 📂files
 ┃ ┃ ┃ ┗ 📜motd
 ┃ ┃ ┣ 📂tasks
 ┃ ┃ ┃ ┣ 📜banner.yml
 ┃ ┃ ┃ ┣ 📜main.yml
 ┃ ┃ ┃ ┣ 📜packages.yml
 ┃ ┃ ┃ ┣ 📜ssh.yml
 ┃ ┃ ┃ ┗ 📜update.yml
 ┃ ┃ ┗ 📂vars
 ┃ ┃ ┃ ┗ 📜main.yml
 ┃ ┣ 📂create-vm-proxmox
 ┃ ┃ ┣ 📂tasks
 ┃ ┃ ┃ ┣ 📜create-vm.yml
 ┃ ┃ ┃ ┣ 📜main.yml
 ┃ ┃ ┃ ┗ 📜notify_telegram.yml
 ┃ ┃ ┣ 📂vars
 ┃ ┃ ┃ ┗ 📜main.yml
 ┣ 📜ansible.cfg
 ┣ 📜hosts
 ┗ 📜main.yml
```

Para chamar as roles eu uso um arquivo "principal" chamado main.yml onde eu passo as variáveis e tem o seguinte conteúdo:

```yaml
- name: PROXMOX | Create a Linux Virtual Machine
  hosts: proxmox
  remote_user: root
  roles: 
    - role: create-vm-proxmox
      vars:
        proxmox_node: pve
        api_user: ansible@pam
        api_token_id: ansible
        storage: vms-storage
        api_token_secret: xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx

- name: LINUX | Install basic packages
  hosts: vms
  become: true
  roles: 
    - config-vm-linux
```

> Nas variáveis acima eu inform o usuário, o token ID e o token secret criados no passo anterior.
{: .prompt-info }

O arquivo hosts é simples e contém o servidor proxmox e as máquinas virtuais criadas:

```text
[proxmox]
192.168.1.250

[vms]
lnx-docker-006 ansible_host=192.168.1.106
```

## Criar uma máquina virtual com Ansible

Estou usando **roles** para criar as máquinas virtuais pois prefiro trabalhar dessa maneira, mas isso não impede que você use as playbooks standalone, a primeira role que cria a máquina virtual tem alguns pontos importantes como variáveis e configurações.

Seguindo a minha estrutura de pastas o conteúdo da role ficará da seguinte forma:

```
📦create-vm-proxmox
 ┣ 📂tasks
 ┃ ┣ 📜create-vm.yml
 ┃ ┣ 📜main.yml
 ┃ ┗ 📜notify_telegram.yml
 ┣ 📂vars
 ┃ ┗ 📜main.yml
 ```

Como vocês sabem, cada máquina virtual no Proxmox tem um ID, o ID das minhas máquinas virtuais estão começando em 100 e para a **MINHA** organização eu sempre associo o IP da máquina virtual com o ID, por exemplo: a máquina virtual com ID 105 terá o IP 192.168.1.**105**, mas caso não usem dessa forma podem excluir a task **Getting the VM ID** e **Setting the IP**.

Na task **Print VM IP and Name to HOST file** eu adiciono a máquina virtual criada ao meu arquivo de hosts do Ansible, caso você prefira fazer isso de forma manual pode também remover essa task.

```yaml
--- {% raw %}
- name: Creating the Virtual Machine
  become: true
  become_user: root
  proxmox_kvm:
    api_user        : "{{ api_user }}"
    api_token_id    : "{{ api_token_id }}"
    api_token_secret: "{{ api_token_secret }}"
    api_host        : "{{ ansible_default_ipv4.address }}" 
    clone           : ubuntu-template
    name            : "{{ vm_name }}"
    node            : "{{ proxmox_node }}"
    storage         : "{{ storage }}"
    timeout         : 500

- name: Wait for VM to be created
  pause:
    seconds: 10

- name: Getting the VM ID
  shell: qm list | grep "{{ vm_name }}" | awk '{ print $1 }'
  register: thevmid

- name: Setting the IP
  shell: qm set "{{ thevmid.stdout }}" --ipconfig0 ip=192.168.1.{{ thevmid.stdout }}/24,gw=192.168.1.1
  # Config the IP 192.168.1.x and gateway 192.168.1.1

- name: Starting the VM "{{ vm_name }}"
  proxmox_kvm:
    api_user        : "{{ api_user }}"
    api_token_id    : "{{ api_token_id }}"
    api_token_secret: "{{ api_token_secret }}"
    api_host        : "{{ ansible_default_ipv4.address }}"
    name            : "{{ vm_name }}"
    node            : "{{ proxmox_node }}"
    state           : started

- name: Print VM IP and Name to HOST file
  ansible.builtin.lineinfile:
    path: hosts
    line: '{{ vm_name }} ansible_host=192.168.1.{{ thevmid.stdout }}'
  delegate_to: localhost

- name: Refresh inventory in memory
  meta: refresh_inventory

- name: Wait for VM to be started
  pause:
    seconds: 50
... {% endraw %}
```

As variáveis são declaradas no arquivo **vars/main.yml**:

```yaml
---
# vars file for create-vm-proxmox
proxmox_node:
api_token_id:
api_user:
storage:
api_token_secret:
```

Após a criação da máquina virtual podemos usar uma task para receber uma notificação no Telegram informando que a máquina virtual foi criado, para isso uso o seguinte código:

```yaml
---
- name: Telegram | Send message
  community.general.telegram:
    token: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    api_args:
      chat_id: -4xxxxxxxx335
      parse_mode: plain
      text: |
        ### Your Server is READY!! ###
        --------------------------------------

        Server: "{{ vm_name }}"
        IP ADDRESS: "192.168.1.{{ thevmid.stdout }}"
        'URL': ssh://luiz@192.168.1.{{ thevmid.stdout }}
        --------------------------------------   
...
```

> Para integrar com o Telegram é necessário a criação de um bot, vou deixar o link abaixo de como fazer isso, pois precisa passar o **token** e o **chat_id**
{: .prompt-tip }

## Configurar uma máquina virtual Linux com Ansible

Na role que uso para configurar a máquina virtual criada ou alguma já existente esta dividida da forma abaixo, lembrando que se tiver alguma task que não queira executar é só comentar no arquivo **tasks/main.yml**:

```
📦config-vm-linux
 ┣ 📂files
 ┃ ┗ 📜motd
 ┣ 📂tasks
 ┃ ┣ 📜banner.yml
 ┃ ┣ 📜main.yml
 ┃ ┣ 📜upgrade.yml
 ┃ ┣ 📜ssh.yml
 ┃ ┗ 📜install_packages.yml
 ┗ 📂vars
 ┃ ┗ 📜main.yml
```

### main.yml

Arquivo para chamar as tasks dessa role:

```yaml
---
# tasks file for config-vm-linux
- name: LINUX | Config Motd banner
  import_tasks: banner.yml

- name: LINUX | Config SSH Server
  import_tasks: ssh.yml
  
- name: LINUX | Install basic packages
  import_tasks: install_packages.yml

- name: LINUX | Upgrade SO
  import_tasks: upgrade.yml
```

### banner.yml

Task para configurar o ***motd*** com o arquivo que está na pasta **files/motd**:

```yaml
- name: Server | Copy MTOD to server
  ansible.builtin.copy:
    src: motd
    dest: /etc/motd
```

O arquivo **files/motd** tem o seguinte banner:

```
    _    ____      _    _   _ _____ _____ ____
   / \  |  _ \    / \  | \ | |_   _| ____/ ___|
  / _ \ | |_) |  / _ \ |  \| | | | |  _| \___ \
 / ___ \|  _ <  / ___ \| |\  | | | | |___ ___) |
/_/   \_\_| \_\/_/   \_\_| \_| |_| |_____|____/
```

> Você pode criar seu próprio banner <a href="https://manytools.org/hacker-tools/ascii-banner/" target="_blank">nesse link</a> 
{: .prompt-tip }

### install_packages.yml

Task para instalar os pacotes que eu definir na variável **vars/main.yml**:

```yaml

- name: Remove apt lock file
  vars:
    my_var: "{{lock_file}}"   
  file:
    path: "{{lock_file}}"
    state: absent
  with_items:
    - "/var/lib/dpkg/lock"
    - "/var/lib/dpkg/lock-frontend"
  loop_control:
    loop_var: lock_file

- name: dpkg configure
  command: dpkg --configure -a

- name: APT | Installing Linux Apps
  ansible.builtin.apt:
    name: '{{ packages }}'
    state: latest
```

### ssh.yml

Task para configurar o serviço de SSH:

```yaml
- name: SSH | Disable password authentication for root
  lineinfile:
    path: /etc/ssh/sshd_config
    state: present
    regexp: '^#?PermitRootLogin'
    line: 'PermitRootLogin prohibit-password'

- name: SSH | Disable tunneled clear-text passwords
  lineinfile:
    path: /etc/ssh/sshd_config
    state: present
    regexp: '^PasswordAuthentication yes'
    line: 'PasswordAuthentication no'
```

### upgrade.yml

Task para atualizar todos os pacotes e sistema operacional:

```yaml
- name: APT | Upgrade dist
  ansible.builtin.apt:
    upgrade: yes
    update_cache: yes

- name: LINUX | Check if a reboot is required.
  ansible.builtin.stat:
    path: /var/run/reboot-required
    get_checksum: no
  register: reboot_required_file

- name: LINUX | Reboot the server (if required).
  ansible.builtin.reboot:
  when: reboot_required_file.stat.exists == true

- name: APT | Remove dependencies that are no longer required.
  ansible.builtin.apt:
    autoremove: yes
```

### vars/main.yml

Arquivo de variáveis para esta role com os pacotes que será instalado:

```yaml
---
# vars file for config-vm-linux
packages:
  - vim
  - curl
  - wget
  - htop
  - apt-transport-https
  - ca-certificates
  - git
  - unzip
``` 

Com os scripts acima, a máquina estará com uma configuração "básica/inicial" que eu acho pertinente para o meu homelab, sintam-se livre para editar ou remover algum item.

## Executar a playbook do Ansible

Se você seguir a estrutura de pastas e arquivos que eu fiz, você precisará estar na raiz, onde se encontra o arquivo de hosts  do Ansilbe e o arquivo main.yml, executar o comando passando na variável **vm_name** o nome da máquina virtual que quer criar, no exemplo abaixo a máquina virtual terá o nome de **lnx-teste-01**:

```bash
ansible-playbook main.yml  --extra-vars vm_name="lnx-teste-01"
```

A playbook se executada com sucesso, trará o resultado abaixo, lembrando que 192.168.1.250 é meu servidor proxmox:

![create-config-vm-proxmox-ansible](/assets/img/26/06.png){: .shadow .rounded-10}

E também é enviado uma mensagem no Telegram, pois eu geralmente executo a playbook e vou fazer outra coisa 😊 😜:

![create-config-vm-proxmox-ansible](/assets/img/26/07.png){: .shadow .rounded-10}

<br>

A segunda parte é a role para configurar o servidor linux e traz o seguinte resultado se executada com sucesso:

![create-config-vm-proxmox-ansible](/assets/img/26/08.png){: .shadow .rounded-10}

> Pessoal eu separei para trazer os prints, vocês podem e eu faço isso, executar tudo de uma vez!
{: .prompt-info }

## Concluindo!

Isso tudo poderia ser feito manualmente ou até pelo portal web do Proxmox, mas usar o Ansible me força a estudar e aprender cada vez mais essa tecnologia, e como o Ansible não faz parte do meu dia a dia atualmente sempre encontro desafios, mas é algo que quero estar com o conhecimento afiado! 

Bom pessoal, espero que tenha gostado e que esse artigo seja útil a vocês!

## Artigos relacionados

<a href="https://core.telegram.org/bots/tutorial" target="_blank">Bot Telegram</a> 


Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
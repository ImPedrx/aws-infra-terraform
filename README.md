# aws-infra-terraform

Infraestrutura como código para provisionamento automatizado de recursos na AWS, utilizando Terraform orquestrado via GitHub Actions.

## Visão Geral

Este repositório gerencia toda a infraestrutura necessária para hospedar o [Aerrnova IT Tools](https://github.com/seu-usuario/aws-cicd-deploy) em produção na AWS. O provisionamento é feito via Terraform e executado por pipelines no GitHub Actions com gatilho manual, permitindo controle total sobre quando aplicar ou destruir recursos.

## Arquitetura

```
GitHub Actions (manual)
        │
        ▼
   Terraform
        │
        ├── EC2 (Docker Host)
        ├── Security Group (HTTP, HTTPS, SSH)
        ├── ECR (Elastic Container Registry)
        └── ALB (Application Load Balancer)
```

## Stack

- **AWS** — EC2, ECR, ALB, Security Groups, VPC
- **Terraform** — Infraestrutura como código (IaC)
- **GitHub Actions** — Orquestração do pipeline de infra
- **Zabbix** — Monitoramento de CPU, memória, containers e serviços

## Pipeline de Infraestrutura

O workflow é disparado **manualmente** via `workflow_dispatch` com três ações disponíveis:

| Ação | Descrição |
|------|-----------|
| `plan` | Exibe o plano de execução sem aplicar mudanças |
| `apply` | Provisiona ou atualiza os recursos na AWS |
| `destroy` | Destrói todos os recursos (requer confirmação) |

Para destruir é necessário digitar `DESTROY` como confirmação — isso evita acidentes.

## Recursos Provisionados

- **EC2 (t3.micro)** — Instância que roda o Docker e hospeda o container da aplicação
- **Security Group** — Regras de firewall liberando HTTP (80), HTTPS (443) e SSH (22)
- **ECR** — Registro privado para armazenar as imagens Docker da aplicação
- **ALB** — Load Balancer para distribuição de tráfego

## Monitoramento

O Zabbix está instalado na própria EC2 e coleta métricas em tempo real:

- Uso de CPU
- Utilização de memória
- Status dos containers Docker
- Disponibilidade dos serviços

## Como Usar

### Pré-requisitos

- Conta AWS configurada
- Secrets configurados no GitHub:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION`

### Executando o Pipeline

1. Acesse a aba **Actions** no GitHub
2. Selecione o workflow **terraform.yml**
3. Clique em **Run workflow**
4. Escolha a ação desejada: `plan`, `apply` ou `destroy`
5. Confirme e acompanhe os logs em tempo real

## Repositório Relacionado

- [aws-cicd-deploy](https://github.com/seu-usuario/aws-cicd-deploy) — Repositório da aplicação com pipeline de build e deploy automatizado

---

Desenvolvido por **Pedro Henrique Martins de Paula Ribeiro**

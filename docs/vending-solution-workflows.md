## Overview

## Table of Contents

## Workflows

- .github\workflows\vending-request-handler-workflow.yml
- .github\workflows\vending-request-processor-workflow.yml

### Vending Solution Request Processor

```mermaid
flowchart TD
    A[Submit Request] -->|JSON| B(Validate JSON)
    B --> C{Is Valid}
    C -->|No| Z[End]
    C -->|Yes| D(Save Request)
    D --> E(Create Subscription & Build YAML)
    E --> F(Create Subscription & Build tfvars)
    F --> G(Create branch features/subscriptions/_global_id_)
    G --> H(Submit Pull Request)
    H -->|complete| Z

```

### Vending Solution Request Deployment

```mermaid
flowchart TD
        A[Approve Pull Request] -->|event| B{Is Merged}    
        B -->|No| Z[End]
        B -->|Yes| C(Extract Global_ID)
        C -->|use tfvars|D(Deploy Subscriptions)
        D -->D1(TF Validate)
            subgraph Terraform1
                direction RL
                D1-->D2(TF Plan)
                D2-->D3(TF Inspect)
                D3-->D4(TF Apply)
            end
        Terraform1 -->E(Update Build YAML with Subscription ID)
        E -->F(Deploy Resources)
        F -->F1(TF Validate)
            subgraph Terraform2
                direction RL
                F1-->F2(TF Plan)
                F2-->F3(TF Inspect)
                F3-->F4(TF Apply)
            end
        Terraform2 -->G(Submit Pull Request)
        G -->|complete|Z    
```
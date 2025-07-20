# RAM TECH Token (RAM_CEO_TOKEN)

## Visão Geral

O contrato `RAM_CEO_TOKEN` é um token BEP20/ERC20 avançado, desenvolvido para operar na Binance Smart Chain (BSC), com funcionalidades de taxas dinâmicas, liquidez automatizada, queima de tokens, controle administrativo e integração com PancakeSwap.

---

## Funcionalidades Principais

- **Taxas de Compra e Venda**: Taxas configuráveis para operações de compra e venda.
- **Taxa de Liquidez**: Parte das taxas é usada para adicionar liquidez automaticamente.
- **Taxa de Queima (Burn)**: Tokens são queimados em cada transação, reduzindo o supply.
- **Carteira de Marketing**: Parte das taxas é enviada para uma carteira de marketing.
- **Controle de Swap Interno**: O contrato pode trocar tokens acumulados por BNB automaticamente.
- **Administração Segura**: Funções administrativas separadas entre owner e admin.
- **Exceções de Taxa**: Endereços podem ser isentos de taxas.
- **Limite de Queima**: Não permite que o supply caia abaixo de 21 milhões de tokens em queimas automáticas.
- **Gestão de Pares**: Suporte a múltiplos pares de liquidez.

---

## Variáveis Importantes

- `buyFee`, `sellFee`, `burnFee`, `liquidityFee`: Taxas percentuais (em relação ao denominador, padrão 100).
- `marketingWallet`: Endereço que recebe a taxa de marketing.
- `admin`, `ca`: Endereços administrativos para funções sensíveis.
- `enableInternalSwap`: Habilita/desabilita o swap automático de tokens por BNB.
- `burnInternal`: Habilita/desabilita a queima interna de tokens.
- `amountSwapTheBalance`: Quantidade de tokens que, ao ser atingida no contrato, dispara o swap automático.
- `stopBurnTx`: Supply mínimo para queima automática (21 milhões de tokens).
- `newPair`: Lista de pares adicionais de liquidez.

---

## Funções Principais

### Funções BEP20/ERC20
- `transfer`, `transferFrom`, `approve`, `allowance`, `balanceOf`, `totalSupply`, `decimals`, `symbol`, `name`

### Funções de Taxa/Administração
- `setBuyFee(uint256)`, `setSellFee(uint256)`, `setLiquidityFee(uint256)`, `setBurnFee(uint256)`
- `setEnableInternalSwap(bool)`, `setAddressExempt(address,bool)`, `setSwapAmountNew(uint256,bool)`, `setBurnInternalStatus(bool)`
- `setNewPair(address)`, `setMarketingWallet(address)`, `forceSwap(bool)`, `withdrawNativeBNB()`, `withdrawTokens(address)`, `setNewCa(address)`, `additionalBurnTokens(uint256)`

### Lógica de Transferência
- **Compra**: Taxas deduzidas do destinatário.
- **Venda**: Taxas deduzidas do remetente.
- **Transferência normal**: Sem taxas.
- **Swap automático**: Quando o saldo do contrato atinge `amountSwapTheBalance`, tokens são trocados por BNB, parte vai para liquidez, parte para marketing e pode haver queima.

---

## Controle de Acesso
- **Owner**: Pode ativar/desativar trading e ajustar taxas.
- **Admin**: Pode executar funções de swap, isenção, ajuste de pares, marketing, queima adicional, etc.
- **Exceções**: Endereços podem ser isentos de taxas e restrições.

---

## Eventos
- Diversos eventos para rastrear mudanças de taxas, swaps, queimas, adição de liquidez, retiradas, etc.

---

## Fluxograma do Funcionamento do Contrato

```mermaid
flowchart TD
    A[Usuário inicia interação] --> B{Tipo de operação}
    B -- Transferência --> C1[Função transfer/transferFrom]
    C1 --> D1{Tipo de transferência}
    D1 -- Compra (par -> usuário) --> E1[Aplica buyFee, burnFee, liquidityFee]
    E1 --> F1[Deduz taxas do destinatário]
    F1 --> G1[Atualiza saldos e supply]
    D1 -- Venda (usuário -> par) --> E2[Aplica sellFee, burnFee, liquidityFee]
    E2 --> F2[Deduz taxas do remetente]
    F2 --> G2[Atualiza saldos e supply]
    D1 -- Transferência normal --> G3[Sem taxas, apenas transfere]
    G1 & G2 & G3 --> H{Saldo do contrato >= amountSwapTheBalance?}
    H -- Sim --> I[_swapTokensForBNB]
    I --> J[Swap tokens por BNB]
    J --> K[Adiciona liquidez]
    J --> L[Envia BNB para marketingWallet]
    J --> M[Queima tokens se burnInternal]
    H -- Não --> N[Fim da transferência]
    B -- Função administrativa --> O[Funções admin/owner]
    O --> P1[setEnableInternalSwap]
    O --> P2[setAddressExempt]
    O --> P3[setSwapAmountNew]
    O --> P4[setBurnInternalStatus]
    O --> P5[setNewPair]
    O --> P6[setMarketingWallet]
    O --> P7[forceSwap]
    O --> P8[withdrawNativeBNB]
    O --> P9[withdrawTokens]
    O --> P10[setNewCa]
    O --> P11[additionalBurnTokens]
    P1 & P2 & P3 & P4 & P5 & P6 & P7 & P8 & P9 & P10 & P11 --> N
    N[Operação concluída]
```

---

## Observações
- O contrato não utiliza Permit2, UniversalRouter ou qualquer padrão de aprovação avançada.
- Todas as interações externas são com PancakeSwap (router, factory) e contratos BEP20.
- Comentários e mensagens de erro estão em inglês, conforme convenção do projeto.

---

## Contato do Desenvolvedor
- Telegram: https://t.me/AbraaoOliveira47
- Facebook: https://www.facebook.com/xXPerfiladorXx
- WhatsApp: (74) 9 9194-3796

---

## Licença
MIT

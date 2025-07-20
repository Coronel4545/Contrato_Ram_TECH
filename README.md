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

## Fluxograma Detalhado do Funcionamento do Contrato

```mermaid
flowchart TD
    A[Usuário/Admin chama função] --> B{Tipo de função}
    B -- Transferência --> C1[Função transfer/transferFrom]
    C1 --> D1{Tipo de transferência}
    D1 -- Compra (par -> usuário) --> E1[Aplica buyFee, burnFee, liquidityFee]
    D1 -- Venda (usuário -> par) --> E2[Aplica sellFee, burnFee, liquidityFee]
    D1 -- Transferência normal --> E3[Sem taxas]
    E1 & E2 & E3 --> F[Atualiza saldos e supply]
    F --> G{Saldo contrato >= amountSwapTheBalance?}
    G -- Sim --> H[_swapTokensForBNB]
    H --> I[Distribui BNB: liquidez, marketing, queima (se burnInternal)]
    G -- Não --> J[Fim da transferência]
    H --> J

    B -- Função administrativa --> K{Qual função?}

    %% setEnableInternalSwap
    K -- setEnableInternalSwap(_value) --> L1{_value é true ou false?}
    L1 -- true --> M1[Habilita swap interno]
    L1 -- false --> M2[Desabilita swap interno]
    M1 & M2 --> Z

    %% setAddressExempt
    K -- setAddressExempt(account, exempt) --> L2{exempt é true ou false?}
    L2 -- true --> M3[Isenta account de taxas]
    L2 -- false --> M4[Remove isenção de account]
    M3 & M4 --> Z

    %% setSwapAmountNew
    K -- setSwapAmountNew(_newAmountSwap, _confirm) --> L3{_confirm é true?}
    L3 -- true --> M5[Atualiza amountSwapTheBalance]
    L3 -- false --> M6[Não altera valor]
    M5 & M6 --> Z

    %% setBurnInternalStatus
    K -- setBurnInternalStatus(_valueBurn) --> L4{_valueBurn é true ou false?}
    L4 -- true --> M7[Habilita queima interna]
    L4 -- false --> M8[Desabilita queima interna]
    M7 & M8 --> Z

    %% setNewPair
    K -- setNewPair(_newPair) --> L5{_newPair já existe?}
    L5 -- Não --> M9[Adiciona novo par]
    L5 -- Sim --> M10[Rejeita: par já existe]
    M9 & M10 --> Z

    %% setMarketingWallet
    K -- setMarketingWallet(newMarketingWallet) --> M11[Atualiza carteira de marketing]
    M11 --> Z

    %% forceSwap
    K -- forceSwap(_confirm) --> L6{_confirm é true?}
    L6 -- true --> M12[Força swap de tokens por BNB]
    L6 -- false --> M13[Não executa swap]
    M12 & M13 --> Z

    %% withdrawNativeBNB
    K -- withdrawNativeBNB() --> M14[Transfere BNB para marketingWallet]
    M14 --> Z

    %% withdrawTokens
    K -- withdrawTokens(token) --> M15[Transfere tokens para restitutionAddress]
    M15 --> Z

    %% setNewCa
    K -- setNewCa(_newCa) --> M16[Atualiza endereço ca]
    M16 --> Z

    %% additionalBurnTokens
    K -- additionalBurnTokens(_amountBurn) --> L7{_amountBurn > 0 e permitido?}
    L7 -- Sim --> M17[Queima tokens do ca]
    L7 -- Não --> M18[Rejeita operação]
    M17 & M18 --> Z

    Z[Operação administrativa concluída]
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

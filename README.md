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
    B -- Transferência --> C1[Função transfer ou transferFrom]
    C1 --> D1{Tipo de transferência}
    D1 -- Compra (par para usuário) --> E1[Aplica taxas de compra]
    D1 -- Venda (usuário para par) --> E2[Aplica taxas de venda]
    D1 -- Transferência normal --> E3[Sem taxas]
    E1 & E2 & E3 --> F[Atualiza saldos e supply]
    F --> G{Saldo contrato >= amountSwapTheBalance?}
    G -- Sim --> H[Executa swapTokensForBNB]
    H --> I[Distribui BNB: liquidez/marketing/queima]
    G -- Não --> J[Fim da transferência]
    H --> J

    B -- Função administrativa --> K{Qual função?}
    K -- setEnableInternalSwap(true) --> M1[Habilita swap interno]
    K -- setEnableInternalSwap(false) --> M2[Desabilita swap interno]
    K -- setAddressExempt(account, true) --> M3[Isenta account de taxas]
    K -- setAddressExempt(account, false) --> M4[Remove isenção de account]
    K -- setSwapAmountNew(valor, true) --> M5[Atualiza amountSwapTheBalance]
    K -- setSwapAmountNew(valor, false) --> M6[Não altera valor]
    K -- setBurnInternalStatus(true) --> M7[Habilita queima interna]
    K -- setBurnInternalStatus(false) --> M8[Desabilita queima interna]
    K -- setNewPair(novoPar) --> M9[Adiciona novo par]
    K -- setMarketingWallet(novaWallet) --> M11[Atualiza carteira de marketing]
    K -- forceSwap(true) --> M12[Força swap de tokens por BNB]
    K -- forceSwap(false) --> M13[Não executa swap]
    K -- withdrawNativeBNB() --> M14[Transfere BNB para marketingWallet]
    K -- withdrawTokens(token) --> M15[Transfere tokens para restitutionAddress]
    K -- setNewCa(novoCa) --> M16[Atualiza endereço ca]
    K -- additionalBurnTokens(valor > 0) --> M17[Queima tokens do ca]
    K -- additionalBurnTokens(valor <= 0) --> M18[Rejeita operação]
    M1 & M2 & M3 & M4 & M5 & M6 & M7 & M8 & M9 & M11 & M12 & M13 & M14 & M15 & M16 & M17 & M18 --> Z[Operação administrativa concluída]
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

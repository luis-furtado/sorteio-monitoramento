# sorteio-monitoramento

Sorteio quinzenal do **monitor do Cycle** do time Plus. Roda em GitHub Actions toda segunda-feira em que começa um novo Cycle (a cada 14 dias) e posta o resultado no canal `#alertas-criticos` do Slack.

## O que o monitor faz no Cycle

- Acompanha os serviços de forma exploratória (dashboards, logs, métricas)
- Detecta anomalias e comportamentos fora do padrão
- Responde e encaminha as notificações de alertas no canal
- Apresenta as **3 principais anomalias do ciclo** no fechamento

## Estrutura

```
sorteio-monitoramento/
├── .github/workflows/monitoramento.yml   # Agendamento, guard quinzenal e post no Slack
├── teams/monitoramento.txt               # Participantes (um por linha)
├── sorteio.sh                            # Script de sorteio sem repetição
└── .sorteio-state/                       # Estado persistido pelo pipeline
```

## Como funciona

- **Sem repetição:** ninguém é sorteado de novo até todos terem sido monitores na rodada. Ao virar a rodada, o último monitor não pode ser o primeiro da próxima (ninguém pega dois Cycles seguidos).
- **Quinzenal:** o cron roda toda segunda às 04:00 BRT, mas o guard só segue quando `(hoje - CYCLE_ANCHOR) % 14 == 0`. `CYCLE_ANCHOR` é uma segunda em que um Cycle começou (`2026-10-12`).
- **Horário do post:** o job aguarda até `POST_TIME` (09:00 BRT) para postar.
- **Idempotente:** o início do Cycle sorteado fica em `.sorteio-state/last-cycle`; reexecuções no mesmo Cycle não sorteiam de novo.
- **Estado:** `.sorteio-state/monitoramento/remaining.txt` (quem falta na rodada) e `last.txt` (último monitor), commitados pelo bot.

## Disparo manual

*Actions → Sorteio Monitor do Cycle → Run workflow*. Marque **force** para sortear na hora o monitor do Cycle em andamento (útil se o agendamento falhar ou no primeiro uso). Se o Cycle atual já tiver monitor, o workflow não sorteia de novo.

## Secret necessário

Configure em *Settings → Secrets and variables → Actions*:

| Secret | Descrição |
|---|---|
| `SLACK_WEBHOOK_URL_MONITORAMENTO` | Webhook do canal `#alertas-criticos` |

> Nunca commite a URL do webhook no repositório: ela dá permissão de postar no canal.

## Gerenciando participantes

Edite `teams/monitoramento.txt` (linhas com `#` são ignoradas). Quem sair do arquivo é removido automaticamente da rodada em andamento.

Se a cadência dos Cycles mudar, ajuste `CYCLE_ANCHOR` e `CYCLE_DAYS` no workflow.

## Uso local

```bash
./sorteio.sh teams/monitoramento.txt /tmp/estado-teste
```

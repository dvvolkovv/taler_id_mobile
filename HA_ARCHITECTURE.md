# TalerID — План горизонтального масштабирования и HA

## Текущее состояние (DEV, апрель 2026)

| Сервер | IP | Роль |
|--------|----|------|
| DEV бэкенд | 89.169.55.217 | NestJS, PostgreSQL, Redis, LiveKit |
| Extension | 77.73.131.137 | MinIO S3 (Docker), TeslaPay сервисы |

**S3:** `https://s3-dev.taler.tirol` → MinIO на 77.73.131.137
**Бакеты:** `taler-id-files` (мессенджер), `taler-id-documents` (KYC, AES-256)

---

## Целевая архитектура

```
                    VIP (floating IP)
                    staging.id.taler.tirol
                          │
               ┌──────────┴──────────┐
            [LB-1]               [LB-2]
            HAProxy              HAProxy
            Keepalived MASTER    Keepalived BACKUP
            aeza (один DC)       aeza (один DC)
            приватная сеть L2 между ними
               └──────────┬──────────┘
                     round-robin
          ┌──────────┬────┴────┬──────────┐
          ▼          ▼         ▼          ▼
       [Node 1]  [Node 2]  [Node 3]  [Node N]
       NestJS    NestJS    NestJS    NestJS
          │          │         │          │
          └──────────┴────┬────┴──────────┘
                    WireGuard tunnel
                          │
               ┌──────────┼──────────┐
               ▼          ▼          ▼
          [PostgreSQL] [Redis]   [MinIO]
          primary+     shared    replicated
          replicas
```

---

## Почему именно так

- **LB пара + Keepalived VIP** — нет единой точки отказа на уровне балансировщика. Failover за 1-2 сек через VRRP (gratuitous ARP). Работает т.к. оба LB в одном DC aeza → общий L2.
- **NestJS stateless** — любую ноду можно убить и добавить без downtime.
- **Shared Redis** — нужен для Socket.io Redis adapter (мессенджер между нодами) и JWT refresh tokens.
- **PostgreSQL primary + replicas** — writes на primary, reads можно распределять.
- **MinIO site replication** — файлы на нескольких серверах, доступны при падении одного.

---

## Шаги реализации

### Шаг 1 — Socket.io Redis adapter (КОД, ~20 строк)
**Почему критично:** без этого мессенджер ломается при 2+ нодах.
Если пользователь А на Node 1, пользователь Б на Node 2 — сообщение не дойдёт (Socket.io event живёт в памяти процесса).

```
npm install @socket.io/redis-adapter
```

В `messenger.gateway.ts`:
```typescript
import { createAdapter } from '@socket.io/redis-adapter';
import { createClient } from 'redis';

const pubClient = createClient({ url: process.env.REDIS_URL });
const subClient = pubClient.duplicate();
await Promise.all([pubClient.connect(), subClient.connect()]);
this.server.adapter(createAdapter(pubClient, subClient));
```

### Шаг 2 — Redis на extension сервер (общий для всех нод)
- Остановить Redis на 89.169.55.217
- Поднять Redis в Docker на 77.73.131.137 (рядом с MinIO)
- Обновить `REDIS_URL` на всех нодах

```yaml
# ~/taler-id-infra/docker-compose.yml (добавить)
redis:
  image: redis:7-alpine
  container_name: taler-redis
  ports:
    - "127.0.0.1:6379:6379"
  volumes:
    - /data/taler-redis:/data
  command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
  restart: unless-stopped
```

### Шаг 3 — PostgreSQL streaming replication
- Primary: 89.169.55.217 (уже работает)
- Replica: 77.73.131.137 (read-only, hot standby)
- При падении primary → ручной или `pg_auto_failover` promote

```bash
# На primary (89.169.55.217)
echo "wal_level = replica" >> /etc/postgresql/16/main/postgresql.conf
echo "max_wal_senders = 3" >> /etc/postgresql/16/main/postgresql.conf

# На replica (77.73.131.137)
pg_basebackup -h 89.169.55.217 -U replicator -D /var/lib/postgresql/16/main --wal-method=stream
```

### Шаг 4 — MinIO site replication (двусторонняя)
Файлы будут на обоих серверах — при падении одного MinIO данные доступны с другого.

```bash
mc admin replicate add taler-dev-node1 taler-dev-node2
```

### Шаг 5 — NestJS на Node 2 (77.73.131.137)
- Клонировать репо, настроить .env (тот же, что на Node 1)
- `REDIS_URL` → Redis на extension сервере
- `DATABASE_URL` → PostgreSQL на 89.169.55.217 (primary)
- `pm2 start`

### Шаг 6 — LB пара (два новых VPS на aeza, один DC)
Требования: 1 CPU, 1GB RAM, один датацентр с приватной сетью.

**Keepalived конфиг (LB-1, MASTER):**
```
vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass <пароль>
    }
    virtual_ipaddress {
        <VIP>/32
    }
    notify_master "/etc/keepalived/failover.sh master"
    notify_backup "/etc/keepalived/failover.sh backup"
}
```

**HAProxy конфиг:**
```
frontend https_front
    bind *:443 ssl crt /etc/ssl/taler/
    default_backend nestjs_nodes

backend nestjs_nodes
    balance roundrobin
    option httpchk GET /health
    server node1 89.169.55.217:3000 check inter 2s fall 2 rise 3
    server node2 77.73.131.137:3000 check inter 2s fall 2 rise 3
    # server node3 X.X.X.X:3000 check inter 2s fall 2 rise 3  ← добавить новую ноду
```

### Шаг 7 — DNS переключить на VIP
```
staging.id.taler.tirol  A  <VIP>
```

---

## Добавление новой ноды (Node 3, 4, 5...)

1. Купить VPS на любом провайдере
2. Поднять NestJS (клон репо + `.env` с общим Redis/PG)
3. Добавить строку в HAProxy на обоих LB:
   ```
   server nodeN X.X.X.X:3000 check inter 2s fall 2 rise 3
   ```
4. `systemctl reload haproxy` на LB-1 и LB-2

**Всё. Больше ничего не меняется.**

---

## Масштабирование data tier (когда понадобится)

| Компонент | Текущий лимит | Следующий шаг |
|-----------|--------------|---------------|
| Redis single | ~10-20 нод | Redis Sentinel (3 узла) или Cluster |
| PostgreSQL primary | ~10 нод с PgBouncer | Добавить read replicas, PgBouncer |
| MinIO 2 инстанса | неограниченно | Distributed mode (4+ серверов) |

При 5 нодах data tier не трогаем — Redis и PostgreSQL справляются.

---

## Стоимость инфраструктуры (примерно)

| Сервер | Роль | Цена/мес |
|--------|------|----------|
| 89.169.55.217 (есть) | Node 1, PG primary | — |
| 77.73.131.137 (есть) | Node 2, MinIO, Redis | — |
| LB-1 (новый) | HAProxy + Keepalived | ~3-5$ |
| LB-2 (новый) | HAProxy + Keepalived | ~3-5$ |
| **Итого новых расходов** | | **~6-10$/мес** |

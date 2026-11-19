# PostgreSQL 18.7 com Docker

Serviço local do PostgreSQL 18.7 (`postgres:18.7`) para desenvolvimento. O container escuta apenas em `127.0.0.1:5432`.

## Arquivos

- `docker-compose.yml` — serviço, limites de recurso, healthcheck e volume
- `.env` — senhas (não versionado)
- `init/01-create-user.sh` — cria os papéis `migration` e `developer` na primeira inicialização

## Papéis

| Papel | Origem | Permissões |
| --- | --- | --- |
| `admin` | `POSTGRES_USER` | superusuário do cluster |
| `migration` | script de init | `LOGIN`, `CONNECT` e `CREATE` no banco `app`; dono do schema `public` |
| `developer` | script de init | `LOGIN`, `CONNECT` e `USAGE` no schema `public` |

Objetos criados por `migration` no schema `public` concedem a `developer`, por privilégio padrão:

- tabelas: `SELECT`, `INSERT`, `UPDATE`, `DELETE`
- sequences: `USAGE`, `SELECT`
- funções: `EXECUTE`

`PUBLIC` não tem privilégios no banco `app` nem `CREATE` no schema `public`.

## Variáveis em `.env`

```env
POSTGRES_PASSWORD=
MIGRATION_PASSWORD=
DEVELOPER_PASSWORD=
```

`MIGRATION_PASSWORD` e `DEVELOPER_PASSWORD` precisam ter pelo menos 16 caracteres. O compose recusa subir se alguma das três estiver ausente. Senhas usam `scram-sha-256`.

## Subir

```bash
docker compose up -d
docker compose ps
docker compose logs -f postgres
```

O healthcheck usa `pg_isready -U admin -d app`.

## Conectar

- **Host**: `127.0.0.1`
- **Porta**: `5432`
- **Database**: `app`
- **Username**: `admin`, `migration` ou `developer`
- **Password**: o valor correspondente no `.env`

Exemplo:

```bash
docker compose exec postgres psql -U admin -d app
```

## Observações

- O script em `init/` roda só na primeira inicialização, com o volume vazio.
- `docker compose down -v` remove o volume `postgres_data` e apaga os dados.
- O volume monta em `/var/lib/postgresql` (layout do PostgreSQL 18).
- O initdb usa `--data-checksums`.
- Limites do serviço: 1 CPU e 1 GB de memória; `shm_size` de 256 MB.
- A porta 5432 precisa estar livre em `127.0.0.1`.

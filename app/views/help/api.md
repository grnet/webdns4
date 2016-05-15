# WebDNS API

## General

To access WebDNS API you must have an API `token`. If you are a WebDNS user you can generate your token by clicking on the `API Token` link in the navigation bar.

 * All API request should be routed under the `/api/` prefix.
 * The API token needs to be present as a `?token` URL parameter in all requests.
 * When sending data (POST/PUT) make sure to correctly set the content encoding header (`Content-Enconding: application/json`).

## Debug API

### GET `/ping`
```bash
curl -X GET https://webdns/api/ping
{
  "ok": true,
  "response": "pong"
}
```

### GET `/whoami`
```bash
curl -X GET https://webdns/api/whoami
{
  "ok": true,
  "response": {
    "id": 1,
    "email": "user@example.com"
  }
}
```

## Records API

### GET `/domain/<name>/list`
```bash
curl -X GET https://webdns/api/domain/example.com/list

{
  "ok": true,
  "response": [
    {
      "name": "example.com",
      "content": "ns1.example.com webdns@example.com 2016050301 10800 3600 604800 3600",
      "type": "SOA",
      "ttl": null,
      "prio": null,
      "disabled": false
    },
    {
      "name": "example.com",
      "content": "ns1.example.com",
      "type": "NS",
      "ttl": null,
      "prio": null,
      "disabled": false
    },
    {
      "name": "www.example.com",
      "content": "192.0.0.1",
      "type": "A",
      "ttl": null,
      "prio": null,
      "disabled": false
    },
    {
      "name": "www.example.com",
      "content": "2001:db8::1",
      "type": "AAAA",
      "ttl": null,
      "prio": null,
      "disabled": false
    }
```

### POST `/domain/<name>/bulk`

The `bulk` API allows multiple operations to be perfomed as a single transactional operation. There a three supported operations and they are applied in the following order:

   * `deletes`
   * `upserts`
   * `additions`

`additions` is an array of hashes. Each hash represents a record to be added.
`name`, `type`, `content` and `prio` fields are supported.

`deletes` is an array of hashes. Each hash represents a single record to be deleted. The fields musts match **exactly one** record.

`upserts` is an array of hashes. Each hash represents a records to be added, just like an `addition`. What's different about `upserts` is that, before adding the records, all records matching the hash's `name` and `type` are deleted.

#### Fields
 * `name`: Record name. Should be expanded to contain the full domain name.
 * `type`: Capitilized record type (`'A'`, `'AAAA'`, etc)
 * `prio`: Record priority, if supported.
 * `content`: Record content. When this is a CNANE **do not** include the trailing dot.

```bash
curl -X POST https://webdns/api/domain/example.com/bulk  -H 'Content-Type: application/json' -d '{
  "upserts": [
    {
      "name": "mail.example.com",
      "type": "A",
      "content": "1.2.3.4"
    }
  ],
  "additions": [
    {
      "name": "www.example.com",
      "type": "A",
      "content": "1.2.3.4"
    }
  ]
}'
```
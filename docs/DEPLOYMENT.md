# Static hosting

`dist/`, `demo/` и импортирующая HTML-страница должны обслуживаться по HTTP(S). Backend после build не требуется.

## MIME

- `.js`: `text/javascript`
- `.wasm`: `application/wasm`
- `.json`: `application/json`
- `.dll`, `.dat`: `application/octet-stream`
- `.br`: исходный MIME плюс `Content-Encoding: br`
- `.gz`: исходный MIME плюс `Content-Encoding: gzip` (build package оставляет raw+Brotli; gzip может создать hosting pipeline)

Не возвращайте HTML fallback для отсутствующих runtime assets: это превращается в неочевидную ошибку WebAssembly/assembly loader.

## Cache

Fingerprint-файлы `_framework/*.<hash>.*` можно отдавать с `Cache-Control: public,max-age=31536000,immutable`. `pascalabc-web.js`, `pascalabc-worker.js`, `blazor.boot.json` и `pabc-assets/manifest.json` лучше кэшировать с revalidation, потому что они задают текущий graph assets.

## Пример nginx

```nginx
location /pascalabc/ {
    root /srv/www;
    try_files $uri =404;
}

location ~* /pascalabc/_framework/.*\.[a-z0-9]{8,}\.(wasm|js|dll|dat)$ {
    root /srv/www;
    add_header Cache-Control "public,max-age=31536000,immutable";
}

location ~* \.wasm$ {
    default_type application/wasm;
}
```

Для untrusted student code рекомендуется отдельный origin без auth cookies. CSP и ограничения подробно описаны в `SECURITY.md`.

GitHub Pages подходит, если deployment сохраняет структуру `dist/_framework` и `dist/pabc-assets`, не использует SPA fallback для бинарных файлов и корректно отдаёт `.wasm`. Compression зависит от выбранного CDN/hosting layer.

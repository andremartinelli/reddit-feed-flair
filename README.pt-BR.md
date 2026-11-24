# Feed Flair for Reddit

[English](README.md)

Extensão de navegador que mostra a flair de cada post no feed principal do Reddit (Home, Popular, All e feeds personalizados), com o texto, os emojis e as cores originais, ao lado de "r/subreddit • tempo".

O Reddit novo esconde a flair nesses feeds. A extensão põe de volta.

Não oficial. Sem vínculo com o Reddit, Inc., nem aprovação dele.

## Instalar

Pela Chrome Web Store: [Feed Flair for Reddit](https://chromewebstore.google.com/detail/ljipmpigkkjkbodimengbbacakngcceo).

Pelo código (para usar o código mais novo antes do lançamento):

Testado no Brave. É uma extensão Manifest V3 comum, então deve funcionar também no Chrome, no Edge e em outros navegadores Chromium.

1. Baixe ou clone este repositório.
2. Abra `brave://extensions` (ou `chrome://extensions`, `edge://extensions`).
3. Ligue o **Modo de desenvolvedor** (canto superior direito).
4. Clique em **Carregar sem compactação** e escolha a pasta `reddit-feed-flair`.
5. Recarregue o reddit.com.

Depois de mudar algum arquivo, clique no botão de recarregar do card da extensão e recarregue o Reddit.

Não deixe a versão da loja instalada no mesmo navegador: as duas rodariam juntas, cada post seria buscado duas vezes e a versão da loja pode desenhar a etiqueta antes da sua.

## Como funciona

- No feed principal o Reddit põe um `<shreddit-post-flair>` vazio em todo post. A extensão só considera que o Reddit já mostra a flair quando esse elemento tem texto ou emoji.
- Para cada post sem flair na tela, busca `/comments/<id>.json` com a sua sessão do Reddit: quatro buscas por vez, os posts do topo primeiro. Se o Reddit responder 429 (muitas buscas), espera 5 segundos e tenta de novo.
- Se o JSON falhar, abre a página do post e lê a flair de lá (mais pesado, sem as cores).
- Guarda cada flair por 24 horas no armazenamento local da extensão (até 3.000 posts). Ao recarregar ou voltar ao feed, os posts já vistos aparecem na hora, sem nova busca. Busca que falhou não é guardada.
- Procura posts novos no máximo a cada 200 ms, mesmo com o Reddit mexendo na página sem parar.
- Não mexe na página do próprio post.

## Privacidade

- Não usa servidor externo. Os únicos pedidos vão para www.reddit.com, com a sua sessão, como a própria página faz.
- Permissões: rodar em www.reddit.com e `storage` (o cache acima).

Testado em 23/11/2026: as buscas em lote (`/api/info.json` e `/by_id/...json`) respondem 403 para o navegador, por isso a busca é post por post.

## Se parar de funcionar

Em `content.js`, mude `DEBUG` para `true`, recarregue a extensão e o Reddit: aparece um painel amarelo no canto com quantos posts foram achados, quantas etiquetas foram desenhadas e o resultado das buscas.

Os pontos que dependem do HTML do Reddit:

- `shreddit-post` e os atributos `id` e `permalink` do post;
- `[id*='credit-bar']`, a linha onde a etiqueta entra;
- `shreddit-post-flair`, a flair que o próprio Reddit desenha.

Erros aparecem no console da página com o prefixo `[Feed Flair for Reddit]`.

## Publicar uma nova versão

1. Mude o código e teste: recarregue a extensão em `brave://extensions` e depois o Reddit.
2. Aumente `version` no `manifest.json` (por exemplo 1.3.0 → 1.3.1). A Chrome Web Store recusa um pacote com versão que não seja maior que a publicada.
3. Faça o commit e o push.
4. Crie um GitHub Release com a tag `v<versão>`, por exemplo `gh release create v1.3.1 --generate-notes`. O workflow **Publish to Chrome Web Store** gera o ZIP e manda para revisão. Configuração e detalhes: `store/automation.md`.

Plano B manual: rode `./build.sh` e envie `dist/feed-flair-for-reddit-<versão>.zip` no [painel da Chrome Web Store](https://chrome.google.com/webstore/devconsole), na aba **Pacote** do item.

Os textos e respostas da loja ficam em `store/listing.md`. Se mudar algo no painel, atualize esse arquivo também.

## Licença

[MIT](LICENSE)
